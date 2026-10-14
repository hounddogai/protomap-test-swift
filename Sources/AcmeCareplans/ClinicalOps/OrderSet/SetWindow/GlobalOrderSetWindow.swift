import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global order set window is in its life cycle.
    enum GlobalOrderSetWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global order set window, with what the planners need to act on it.
    final class GlobalOrderSetWindow {
        var code: String
        var name: String
        var attempts: Int
        var ownerID: String
        var clinicianID: String
        var segment: String
        var status: GlobalOrderSetWindowStatus

        init(code: String, name: String, attempts: Int, ownerID: String, clinicianID: String, segment: String, status: GlobalOrderSetWindowStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.ownerID = ownerID
            self.clinicianID = clinicianID
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalOrderSetWindowStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == GlobalOrderSetWindowStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalOrderSetWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global order set window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global order set window") \(code)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> GlobalOrderSetWindow {
            return GlobalOrderSetWindow(
                code: code,
                name: name,
                attempts: attempts,
                ownerID: ownerID,
                clinicianID: clinicianID,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global order set window in status created.
    static func newGlobalOrderSetWindow(_ code: String, name: String) -> GlobalOrderSetWindow {
        return GlobalOrderSetWindow(
            code: code,
            name: name,
            attempts: 0,
            ownerID: "",
            clinicianID: "",
            segment: "",
            status: GlobalOrderSetWindowStatus.created
        )
    }
}
