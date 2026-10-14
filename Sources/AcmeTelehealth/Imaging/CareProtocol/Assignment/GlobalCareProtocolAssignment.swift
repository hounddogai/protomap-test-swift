import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global care protocol assignment is in its life cycle.
    enum GlobalCareProtocolAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a global care protocol assignment and its current status.
    final class GlobalCareProtocolAssignment {
        var code: String
        var title: String
        var rate: Double
        var notes: String
        var encounterID: String
        var attempts: Int
        var status: GlobalCareProtocolAssignmentStatus

        init(code: String, title: String, rate: Double, notes: String, encounterID: String, attempts: Int, status: GlobalCareProtocolAssignmentStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.notes = notes
            self.encounterID = encounterID
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalCareProtocolAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalCareProtocolAssignmentStatus.ready
            case .warming:
                return next == GlobalCareProtocolAssignmentStatus.ready || next == GlobalCareProtocolAssignmentStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == GlobalCareProtocolAssignmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCareProtocolAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global care protocol assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return (Double(attempts) * rate * 100).rounded() / 100
        }

        func copyValue() -> GlobalCareProtocolAssignment {
            return GlobalCareProtocolAssignment(
                code: code,
                title: title,
                rate: rate,
                notes: notes,
                encounterID: encounterID,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global care protocol assignment in status idle.
    static func newGlobalCareProtocolAssignment(_ code: String, title: String) -> GlobalCareProtocolAssignment {
        return GlobalCareProtocolAssignment(
            code: code,
            title: title,
            rate: 0.0,
            notes: "",
            encounterID: "",
            attempts: 0,
            status: GlobalCareProtocolAssignmentStatus.idle
        )
    }
}
