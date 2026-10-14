import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan request is in its life cycle.
    enum AcuityPlanRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a acuity plan request and its current status.
    final class AcuityPlanRequest {
        var code: String
        var name: String
        var ratio: Double
        var budget: Double
        var priority: Int
        var status: AcuityPlanRequestStatus

        init(code: String, name: String, ratio: Double, budget: Double, priority: Int, status: AcuityPlanRequestStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.budget = budget
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

        func canMoveTo(_ next: AcuityPlanRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AcuityPlanRequestStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AcuityPlanRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("acuity plan request") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((budget + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanRequest {
            return AcuityPlanRequest(
                code: code,
                name: name,
                ratio: ratio,
                budget: budget,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a acuity plan request in status draft.
    static func newAcuityPlanRequest(_ code: String, name: String) -> AcuityPlanRequest {
        return AcuityPlanRequest(
            code: code,
            name: name,
            ratio: 0.0,
            budget: 0.0,
            priority: 0,
            status: AcuityPlanRequestStatus.draft
        )
    }
}
