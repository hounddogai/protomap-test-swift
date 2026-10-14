import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score milestone is in its life cycle.
    enum RiskScoreMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A risk score milestone. Its code is unique within a tenant.
    final class RiskScoreMilestone {
        var code: String
        var title: String
        var unit: String
        var margin: Double
        var contactEmail: String
        var status: RiskScoreMilestoneStatus

        init(code: String, title: String, unit: String, margin: Double, contactEmail: String, status: RiskScoreMilestoneStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.margin = margin
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RiskScoreMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> RiskScoreMilestone {
            return RiskScoreMilestone(
                code: code,
                title: title,
                unit: unit,
                margin: margin,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a risk score milestone in status proposed.
    static func newRiskScoreMilestone(_ code: String, title: String) -> RiskScoreMilestone {
        return RiskScoreMilestone(
            code: code,
            title: title,
            unit: "",
            margin: 0.0,
            contactEmail: "",
            status: RiskScoreMilestoneStatus.proposed
        )
    }
}
