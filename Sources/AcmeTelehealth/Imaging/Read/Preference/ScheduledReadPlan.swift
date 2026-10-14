import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled read plan is in its life cycle.
    enum ScheduledReadPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled read plan as the read team keeps it.
    final class ScheduledReadPlan {
        var code: String
        var title: String
        var procedureCode: String
        var minimum: Double
        var visitMinutes: Int
        var visible: Bool
        var archived: Bool
        var quantity: Int
        var bed: String
        var status: ScheduledReadPlanStatus

        init(code: String, title: String, procedureCode: String, minimum: Double, visitMinutes: Int, visible: Bool, archived: Bool, quantity: Int, bed: String, status: ScheduledReadPlanStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.archived = archived
            self.quantity = quantity
            self.bed = bed
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

        func canMoveTo(_ next: ScheduledReadPlanStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
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

        func moveTo(_ next: ScheduledReadPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled read plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netVolume() -> Double {
            return ((Double(quantity) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledReadPlan {
            return ScheduledReadPlan(
                code: code,
                title: title,
                procedureCode: procedureCode,
                minimum: minimum,
                visitMinutes: visitMinutes,
                visible: visible,
                archived: archived,
                quantity: quantity,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled read plan in status requested.
    static func newScheduledReadPlan(_ code: String, title: String) -> ScheduledReadPlan {
        return ScheduledReadPlan(
            code: code,
            title: title,
            procedureCode: "",
            minimum: 0.0,
            visitMinutes: 0,
            visible: false,
            archived: false,
            quantity: 0,
            bed: "",
            status: ScheduledReadPlanStatus.requested
        )
    }
}
