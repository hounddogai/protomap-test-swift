import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority tier is in its life cycle.
    enum PriorityTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a priority tier and its current status.
    final class PriorityTier {
        var code: String
        var label: String
        var cost: Double
        var acuity: Int
        var category: String
        var ceiling: Double
        var status: PriorityTierStatus

        init(code: String, label: String, cost: Double, acuity: Int, category: String, ceiling: Double, status: PriorityTierStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.acuity = acuity
            self.category = category
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityTierStatus) -> Bool {
            switch status {
            case .planned:
                return next == PriorityTierStatus.inProgress || next == PriorityTierStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PriorityTierStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("priority tier") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((cost - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityTier {
            return PriorityTier(
                code: code,
                label: label,
                cost: cost,
                acuity: acuity,
                category: category,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a priority tier in status planned.
    static func newPriorityTier(_ code: String, label: String) -> PriorityTier {
        return PriorityTier(
            code: code,
            label: label,
            cost: 0.0,
            acuity: 0,
            category: "",
            ceiling: 0.0,
            status: PriorityTierStatus.planned
        )
    }
}
