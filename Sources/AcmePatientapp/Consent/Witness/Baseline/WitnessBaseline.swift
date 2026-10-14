import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness baseline is in its life cycle.
    enum WitnessBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A witness baseline. Its code is unique within a tenant.
    final class WitnessBaseline {
        var code: String
        var label: String
        var ownerID: String
        var priority: Int
        var contactEmail: String
        var sequence: Int
        var status: WitnessBaselineStatus

        init(code: String, label: String, ownerID: String, priority: Int, contactEmail: String, sequence: Int, status: WitnessBaselineStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.priority = priority
            self.contactEmail = contactEmail
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessBaselineStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == WitnessBaselineStatus.active || next == WitnessBaselineStatus.closed
            case .active:
                return next == WitnessBaselineStatus.suspended || next == WitnessBaselineStatus.closed
            case .suspended:
                return next == WitnessBaselineStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("witness baseline") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(priority) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessBaseline {
            return WitnessBaseline(
                code: code,
                label: label,
                ownerID: ownerID,
                priority: priority,
                contactEmail: contactEmail,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a witness baseline in status draft.
    static func newWitnessBaseline(_ code: String, label: String) -> WitnessBaseline {
        return WitnessBaseline(
            code: code,
            label: label,
            ownerID: "",
            priority: 0,
            contactEmail: "",
            sequence: 0,
            status: WitnessBaselineStatus.draft
        )
    }
}
