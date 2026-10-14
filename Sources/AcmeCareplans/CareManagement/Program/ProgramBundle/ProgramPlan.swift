import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program plan is in its life cycle.
    enum ProgramPlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One program plan, with what the planners need to act on it.
    final class ProgramPlan {
        var code: String
        var title: String
        var name: String
        var contactEmail: String
        var discount: Double
        var unit: String
        var graceDays: Int
        var margin: Double
        var limit: Int
        var status: ProgramPlanStatus

        init(code: String, title: String, name: String, contactEmail: String, discount: Double, unit: String, graceDays: Int, margin: Double, limit: Int, status: ProgramPlanStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.contactEmail = contactEmail
            self.discount = discount
            self.unit = unit
            self.graceDays = graceDays
            self.margin = margin
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramPlanStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ProgramPlanStatus.draining || next == ProgramPlanStatus.stopped
            case .ready:
                return next == ProgramPlanStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ProgramPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedVolume() -> Double {
            return ((Double(limit) - margin) * 100).rounded() / 100
        }

        func copyValue() -> ProgramPlan {
            return ProgramPlan(
                code: code,
                title: title,
                name: name,
                contactEmail: contactEmail,
                discount: discount,
                unit: unit,
                graceDays: graceDays,
                margin: margin,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a program plan in status idle.
    static func newProgramPlan(_ code: String, title: String) -> ProgramPlan {
        return ProgramPlan(
            code: code,
            title: title,
            name: "",
            contactEmail: "",
            discount: 0.0,
            unit: "",
            graceDays: 0,
            margin: 0.0,
            limit: 0,
            status: ProgramPlanStatus.idle
        )
    }
}
