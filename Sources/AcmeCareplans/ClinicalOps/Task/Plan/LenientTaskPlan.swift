import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient task plan is in its life cycle.
    enum LenientTaskPlanStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A lenient task plan. Its code is unique within a tenant.
    final class LenientTaskPlan {
        var code: String
        var name: String
        var cost: Double
        var segment: String
        var summary: String
        var status: LenientTaskPlanStatus

        init(code: String, name: String, cost: Double, segment: String, summary: String, status: LenientTaskPlanStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.segment = segment
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientTaskPlanStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LenientTaskPlanStatus.published || next == LenientTaskPlanStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LenientTaskPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient task plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient task plan") \(code)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> LenientTaskPlan {
            return LenientTaskPlan(
                code: code,
                name: name,
                cost: cost,
                segment: segment,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient task plan in status created.
    static func newLenientTaskPlan(_ code: String, name: String) -> LenientTaskPlan {
        return LenientTaskPlan(
            code: code,
            name: name,
            cost: 0.0,
            segment: "",
            summary: "",
            status: LenientTaskPlanStatus.created
        )
    }
}
