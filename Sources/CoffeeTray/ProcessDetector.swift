import Foundation
import Darwin

/// Detects and manages `/usr/bin/caffeinate` processes on the system using the
/// native libproc API (proc_listpids + proc_pidpath). No subprocess spawn, so it
/// is cheap enough to call on a 2-second polling timer.
///
/// The app treats caffeinate as a global, singleton resource: the toggle reflects
/// whether ANY caffeinate is running (ours or one started from the CLI), and
/// turning it off kills ALL caffeinate processes. This avoids the problems of
/// multiple concurrent assertions.
enum ProcessDetector {

    static let caffeinatePath = "/usr/bin/caffeinate"

    /// Returns true if any `/usr/bin/caffeinate` process is running.
    static func isCaffeinateRunning() -> Bool {
        caffeinatePids().isEmpty == false
    }

    /// Sends SIGTERM to every running caffeinate process (ours or external).
    static func killAllCaffeinate() {
        for pid in caffeinatePids() {
            kill(pid, SIGTERM)
        }
    }

    /// Enumerate all pids whose executable path is `/usr/bin/caffeinate`.
    private static func caffeinatePids() -> [pid_t] {
        let maxPids: Int32 = 4096
        var pids = [pid_t](repeating: 0, count: Int(maxPids))
        let count = pids.withUnsafeMutableBufferPointer { buf -> Int32 in
            proc_listpids(UInt32(PROC_ALL_PIDS), 0, buf.baseAddress,
                          Int32(buf.count * MemoryLayout<pid_t>.size))
        }
        guard count > 0 else { return [] }

        let written = Int(count) / MemoryLayout<pid_t>.size
        var matches: [pid_t] = []
        for i in 0..<written {
            let pid = pids[i]
            guard pid > 0 else { continue }
            var pathBuf = [CChar](repeating: 0, count: Int(PATH_MAX))
            let len = pathBuf.withUnsafeMutableBufferPointer { buf -> Int32 in
                proc_pidpath(pid, buf.baseAddress, UInt32(buf.count))
            }
            guard len > 0 else { continue }
            let path = String(cString: pathBuf)
            if path == caffeinatePath {
                matches.append(pid)
            }
        }
        return matches
    }
}
