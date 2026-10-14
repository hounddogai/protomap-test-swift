import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling panel plan is in its life cycle.
    enum RollingPanelPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling panel plan as the panel team keeps it.
    final class RollingPanelPlan {
        var code: String
        var label: String
        var discount: Double
        var clinicianID: String
        var facility: String
        var windowDays: Int
        var createdAt: Int
        var segment: String
        var threshold: Double
        var status: RollingPanelPlanStatus

        init(code: String, label: String, discount: Double, clinicianID: String, facility: String, windowDays: Int, createdAt: Int, segment: String, threshold: Double, status: RollingPanelPlanStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.clinicianID = clinicianID
            self.facility = facility
            self.windowDays = windowDays
            self.createdAt = createdAt
            self.segment = segment
            self.threshold = threshold
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

        func canMoveTo(_ next: RollingPanelPlanStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RollingPanelPlanStatus.active || next == RollingPanelPlanStatus.suspended
            case .active:
                return next == RollingPanelPlanStatus.suspended || next == RollingPanelPlanStatus.closed
            case .suspended:
                return next == RollingPanelPlanStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingPanelPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling panel plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedLoad() -> Double {
            return (discount * threshold * 100).rounded() / 100
        }

        func copyValue() -> RollingPanelPlan {
            return RollingPanelPlan(
                code: code,
                label: label,
                discount: discount,
                clinicianID: clinicianID,
                facility: facility,
                windowDays: windowDays,
                createdAt: createdAt,
                segment: segment,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rolling panel plan in status draft.
    static func newRollingPanelPlan(_ code: String, label: String) -> RollingPanelPlan {
        return RollingPanelPlan(
            code: code,
            label: label,
            discount: 0.0,
            clinicianID: "",
            facility: "",
            windowDays: 0,
            createdAt: 0,
            segment: "",
            threshold: 0.0,
            status: RollingPanelPlanStatus.draft
        )
    }
}
