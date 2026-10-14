import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped acuity plan assignment is in its life cycle.
    enum CappedAcuityPlanAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One capped acuity plan assignment, with what the planners need to act on it.
    final class CappedAcuityPlanAssignment {
        var code: String
        var title: String
        var bed: String
        var acuity: Int
        var priority: Int
        var payer: String
        var limit: Int
        var status: CappedAcuityPlanAssignmentStatus

        init(code: String, title: String, bed: String, acuity: Int, priority: Int, payer: String, limit: Int, status: CappedAcuityPlanAssignmentStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.acuity = acuity
            self.priority = priority
            self.payer = payer
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedAcuityPlanAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CappedAcuityPlanAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped acuity plan assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped acuity plan assignment") \(code)"
        }

        func netTotal() -> Double {
            return (Double(limit) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> CappedAcuityPlanAssignment {
            return CappedAcuityPlanAssignment(
                code: code,
                title: title,
                bed: bed,
                acuity: acuity,
                priority: priority,
                payer: payer,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped acuity plan assignment in status requested.
    static func newCappedAcuityPlanAssignment(_ code: String, title: String) -> CappedAcuityPlanAssignment {
        return CappedAcuityPlanAssignment(
            code: code,
            title: title,
            bed: "",
            acuity: 0,
            priority: 0,
            payer: "",
            limit: 0,
            status: CappedAcuityPlanAssignmentStatus.requested
        )
    }
}
