import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network plan is in its life cycle.
    enum NetworkPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A network plan. Its code is unique within a tenant.
    final class NetworkPlan {
        var code: String
        var name: String
        var label: String
        var currency: String
        var acuity: Int
        var timezone: String
        var notes: String
        var visible: Bool
        var procedureCode: String
        var refills: Int
        var status: NetworkPlanStatus

        init(code: String, name: String, label: String, currency: String, acuity: Int, timezone: String, notes: String, visible: Bool, procedureCode: String, refills: Int, status: NetworkPlanStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.currency = currency
            self.acuity = acuity
            self.timezone = timezone
            self.notes = notes
            self.visible = visible
            self.procedureCode = procedureCode
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkPlanStatus) -> Bool {
            switch status {
            case .planned:
                return next == NetworkPlanStatus.scheduled || next == NetworkPlanStatus.cancelled
            case .scheduled:
                return next == NetworkPlanStatus.completed
            case .inProgress:
                return next == NetworkPlanStatus.completed || next == NetworkPlanStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: NetworkPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return ((Double(refills) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkPlan {
            return NetworkPlan(
                code: code,
                name: name,
                label: label,
                currency: currency,
                acuity: acuity,
                timezone: timezone,
                notes: notes,
                visible: visible,
                procedureCode: procedureCode,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a network plan in status planned.
    static func newNetworkPlan(_ code: String, name: String) -> NetworkPlan {
        return NetworkPlan(
            code: code,
            name: name,
            label: "",
            currency: "",
            acuity: 0,
            timezone: "",
            notes: "",
            visible: false,
            procedureCode: "",
            refills: 0,
            status: NetworkPlanStatus.planned
        )
    }
}
