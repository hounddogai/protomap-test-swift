import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set schedule is in its life cycle.
    enum OrderSetScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A order set schedule as the order set team keeps it.
    final class OrderSetSchedule {
        var code: String
        var title: String
        var weight: Double
        var visible: Bool
        var durationMinutes: Int
        var dosageMg: Double
        var copay: Double
        var status: OrderSetScheduleStatus

        init(code: String, title: String, weight: Double, visible: Bool, durationMinutes: Int, dosageMg: Double, copay: Double, status: OrderSetScheduleStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.visible = visible
            self.durationMinutes = durationMinutes
            self.dosageMg = dosageMg
            self.copay = copay
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

        func canMoveTo(_ next: OrderSetScheduleStatus) -> Bool {
            switch status {
            case .draft:
                return next == OrderSetScheduleStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: OrderSetScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return ((weight + copay) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetSchedule {
            return OrderSetSchedule(
                code: code,
                title: title,
                weight: weight,
                visible: visible,
                durationMinutes: durationMinutes,
                dosageMg: dosageMg,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a order set schedule in status draft.
    static func newOrderSetSchedule(_ code: String, title: String) -> OrderSetSchedule {
        return OrderSetSchedule(
            code: code,
            title: title,
            weight: 0.0,
            visible: false,
            durationMinutes: 0,
            dosageMg: 0.0,
            copay: 0.0,
            status: OrderSetScheduleStatus.draft
        )
    }
}
