import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool schedule is in its life cycle.
    enum FloatPoolScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A float pool schedule. Its code is unique within a tenant.
    final class FloatPoolSchedule {
        var code: String
        var name: String
        var payer: String
        var dosageMg: Double
        var margin: Double
        var status: FloatPoolScheduleStatus

        init(code: String, name: String, payer: String, dosageMg: Double, margin: Double, status: FloatPoolScheduleStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.dosageMg = dosageMg
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FloatPoolScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FloatPoolScheduleStatus.resolved
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FloatPoolScheduleStatus.archived
            case .reopened:
                return next == FloatPoolScheduleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return (margin * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolSchedule {
            return FloatPoolSchedule(
                code: code,
                name: name,
                payer: payer,
                dosageMg: dosageMg,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a float pool schedule in status open.
    static func newFloatPoolSchedule(_ code: String, name: String) -> FloatPoolSchedule {
        return FloatPoolSchedule(
            code: code,
            name: name,
            payer: "",
            dosageMg: 0.0,
            margin: 0.0,
            status: FloatPoolScheduleStatus.`open`
        )
    }
}
