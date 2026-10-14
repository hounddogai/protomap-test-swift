import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential milestone is in its life cycle.
    enum CredentialMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One credential milestone, with what the planners need to act on it.
    final class CredentialMilestone {
        var code: String
        var label: String
        var archived: Bool
        var ceiling: Double
        var source: String
        var phone: String
        var clinicianID: String
        var status: CredentialMilestoneStatus

        init(code: String, label: String, archived: Bool, ceiling: Double, source: String, phone: String, clinicianID: String, status: CredentialMilestoneStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.ceiling = ceiling
            self.source = source
            self.phone = phone
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: CredentialMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == CredentialMilestoneStatus.ready
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CredentialMilestoneStatus.draining || next == CredentialMilestoneStatus.stopped
            case .draining:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("credential milestone") \(code)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> CredentialMilestone {
            return CredentialMilestone(
                code: code,
                label: label,
                archived: archived,
                ceiling: ceiling,
                source: source,
                phone: phone,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a credential milestone in status idle.
    static func newCredentialMilestone(_ code: String, label: String) -> CredentialMilestone {
        return CredentialMilestone(
            code: code,
            label: label,
            archived: false,
            ceiling: 0.0,
            source: "",
            phone: "",
            clinicianID: "",
            status: CredentialMilestoneStatus.idle
        )
    }
}
