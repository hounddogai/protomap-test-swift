import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient acuity plan allocation is in its life cycle.
    enum LenientAcuityPlanAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient acuity plan allocation. Its code is unique within a tenant.
    final class LenientAcuityPlanAllocation {
        var code: String
        var title: String
        var visitMinutes: Int
        var clinicianID: String
        var durationMinutes: Int
        var facility: String
        var ownerID: String
        var status: LenientAcuityPlanAllocationStatus

        init(code: String, title: String, visitMinutes: Int, clinicianID: String, durationMinutes: Int, facility: String, ownerID: String, status: LenientAcuityPlanAllocationStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.clinicianID = clinicianID
            self.durationMinutes = durationMinutes
            self.facility = facility
            self.ownerID = ownerID
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

        func canMoveTo(_ next: LenientAcuityPlanAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientAcuityPlanAllocationStatus.approved || next == LenientAcuityPlanAllocationStatus.withdrawn
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

        func moveTo(_ next: LenientAcuityPlanAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient acuity plan allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netValue() -> Double {
            return ((Double(durationMinutes) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LenientAcuityPlanAllocation {
            return LenientAcuityPlanAllocation(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                clinicianID: clinicianID,
                durationMinutes: durationMinutes,
                facility: facility,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a lenient acuity plan allocation in status proposed.
    static func newLenientAcuityPlanAllocation(_ code: String, title: String) -> LenientAcuityPlanAllocation {
        return LenientAcuityPlanAllocation(
            code: code,
            title: title,
            visitMinutes: 0,
            clinicianID: "",
            durationMinutes: 0,
            facility: "",
            ownerID: "",
            status: LenientAcuityPlanAllocationStatus.proposed
        )
    }
}
