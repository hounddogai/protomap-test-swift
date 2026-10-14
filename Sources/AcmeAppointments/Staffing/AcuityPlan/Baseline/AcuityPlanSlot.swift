import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan slot is in its life cycle.
    enum AcuityPlanSlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One acuity plan slot, with what the planners need to act on it.
    final class AcuityPlanSlot {
        var code: String
        var label: String
        var title: String
        var refills: Int
        var weight: Double
        var durationMinutes: Int
        var externalRef: String
        var status: AcuityPlanSlotStatus

        init(code: String, label: String, title: String, refills: Int, weight: Double, durationMinutes: Int, externalRef: String, status: AcuityPlanSlotStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.refills = refills
            self.weight = weight
            self.durationMinutes = durationMinutes
            self.externalRef = externalRef
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

        func canMoveTo(_ next: AcuityPlanSlotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AcuityPlanSlotStatus.approved || next == AcuityPlanSlotStatus.withdrawn
            case .approved:
                return next == AcuityPlanSlotStatus.rejected || next == AcuityPlanSlotStatus.withdrawn
            case .rejected:
                return next == AcuityPlanSlotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((Double(durationMinutes) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanSlot {
            return AcuityPlanSlot(
                code: code,
                label: label,
                title: title,
                refills: refills,
                weight: weight,
                durationMinutes: durationMinutes,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a acuity plan slot in status proposed.
    static func newAcuityPlanSlot(_ code: String, label: String) -> AcuityPlanSlot {
        return AcuityPlanSlot(
            code: code,
            label: label,
            title: "",
            refills: 0,
            weight: 0.0,
            durationMinutes: 0,
            externalRef: "",
            status: AcuityPlanSlotStatus.proposed
        )
    }
}
