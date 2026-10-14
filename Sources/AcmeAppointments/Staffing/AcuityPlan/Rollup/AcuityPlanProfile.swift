import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan profile is in its life cycle.
    enum AcuityPlanProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A acuity plan profile as the acuity plan team keeps it.
    final class AcuityPlanProfile {
        var code: String
        var label: String
        var amount: Double
        var ward: String
        var priority: Int
        var status: AcuityPlanProfileStatus

        init(code: String, label: String, amount: Double, ward: String, priority: Int, status: AcuityPlanProfileStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.ward = ward
            self.priority = priority
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

        func canMoveTo(_ next: AcuityPlanProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AcuityPlanProfileStatus.active || next == AcuityPlanProfileStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AcuityPlanProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netVolume() -> Double {
            return (Double(priority) * amount * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanProfile {
            return AcuityPlanProfile(
                code: code,
                label: label,
                amount: amount,
                ward: ward,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a acuity plan profile in status draft.
    static func newAcuityPlanProfile(_ code: String, label: String) -> AcuityPlanProfile {
        return AcuityPlanProfile(
            code: code,
            label: label,
            amount: 0.0,
            ward: "",
            priority: 0,
            status: AcuityPlanProfileStatus.draft
        )
    }
}
