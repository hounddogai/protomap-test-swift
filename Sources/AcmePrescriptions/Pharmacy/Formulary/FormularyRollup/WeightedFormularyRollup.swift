import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted formulary rollup is in its life cycle.
    enum WeightedFormularyRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One weighted formulary rollup, with what the planners need to act on it.
    final class WeightedFormularyRollup {
        var code: String
        var name: String
        var archived: Bool
        var discount: Double
        var graceDays: Int
        var priority: Int
        var status: WeightedFormularyRollupStatus

        init(code: String, name: String, archived: Bool, discount: Double, graceDays: Int, priority: Int, status: WeightedFormularyRollupStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.discount = discount
            self.graceDays = graceDays
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedFormularyRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedFormularyRollupStatus.queued
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == WeightedFormularyRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedFormularyRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted formulary rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted formulary rollup") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(graceDays) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedFormularyRollup {
            return WeightedFormularyRollup(
                code: code,
                name: name,
                archived: archived,
                discount: discount,
                graceDays: graceDays,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted formulary rollup in status new.
    static func newWeightedFormularyRollup(_ code: String, name: String) -> WeightedFormularyRollup {
        return WeightedFormularyRollup(
            code: code,
            name: name,
            archived: false,
            discount: 0.0,
            graceDays: 0,
            priority: 0,
            status: WeightedFormularyRollupStatus.new
        )
    }
}
