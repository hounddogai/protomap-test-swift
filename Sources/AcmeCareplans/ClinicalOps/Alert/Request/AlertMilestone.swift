import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert milestone is in its life cycle.
    enum AlertMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A alert milestone. Its code is unique within a tenant.
    final class AlertMilestone {
        var code: String
        var title: String
        var quantity: Int
        var timezone: String
        var patientRef: String
        var status: AlertMilestoneStatus

        init(code: String, title: String, quantity: Int, timezone: String, patientRef: String, status: AlertMilestoneStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.timezone = timezone
            self.patientRef = patientRef
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

        func canMoveTo(_ next: AlertMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
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
                switch next {
                case .retired:
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

        func moveTo(_ next: AlertMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> AlertMilestone {
            return AlertMilestone(
                code: code,
                title: title,
                quantity: quantity,
                timezone: timezone,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a alert milestone in status created.
    static func newAlertMilestone(_ code: String, title: String) -> AlertMilestone {
        return AlertMilestone(
            code: code,
            title: title,
            quantity: 0,
            timezone: "",
            patientRef: "",
            status: AlertMilestoneStatus.created
        )
    }
}
