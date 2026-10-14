import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted care protocol rollup is in its life cycle.
    enum WeightedCareProtocolRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted care protocol rollup as the care protocol team keeps it.
    final class WeightedCareProtocolRollup {
        var code: String
        var label: String
        var discount: Double
        var summary: String
        var limit: Int
        var copay: Double
        var status: WeightedCareProtocolRollupStatus

        init(code: String, label: String, discount: Double, summary: String, limit: Int, copay: Double, status: WeightedCareProtocolRollupStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.summary = summary
            self.limit = limit
            self.copay = copay
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

        func canMoveTo(_ next: WeightedCareProtocolRollupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WeightedCareProtocolRollupStatus.resolved || next == WeightedCareProtocolRollupStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: WeightedCareProtocolRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted care protocol rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted care protocol rollup") \(code)"
        }

        func projectedValue() -> Double {
            return ((copay - discount) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCareProtocolRollup {
            return WeightedCareProtocolRollup(
                code: code,
                label: label,
                discount: discount,
                summary: summary,
                limit: limit,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted care protocol rollup in status open.
    static func newWeightedCareProtocolRollup(_ code: String, label: String) -> WeightedCareProtocolRollup {
        return WeightedCareProtocolRollup(
            code: code,
            label: label,
            discount: 0.0,
            summary: "",
            limit: 0,
            copay: 0.0,
            status: WeightedCareProtocolRollupStatus.`open`
        )
    }
}
