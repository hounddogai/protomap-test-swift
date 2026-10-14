import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan item is in its life cycle.
    enum AcuityPlanItemStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a acuity plan item and its current status.
    final class AcuityPlanItem {
        var code: String
        var title: String
        var priority: Int
        var segment: String
        var description: String
        var status: AcuityPlanItemStatus

        init(code: String, title: String, priority: Int, segment: String, description: String, status: AcuityPlanItemStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.segment = segment
            self.description = description
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

        func canMoveTo(_ next: AcuityPlanItemStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AcuityPlanItemStatus.rejected || next == AcuityPlanItemStatus.withdrawn
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

        func moveTo(_ next: AcuityPlanItemStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan item \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> AcuityPlanItem {
            return AcuityPlanItem(
                code: code,
                title: title,
                priority: priority,
                segment: segment,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a acuity plan item in status proposed.
    static func newAcuityPlanItem(_ code: String, title: String) -> AcuityPlanItem {
        return AcuityPlanItem(
            code: code,
            title: title,
            priority: 0,
            segment: "",
            description: "",
            status: AcuityPlanItemStatus.proposed
        )
    }
}
