import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal closure bundle is in its life cycle.
    enum SeasonalClosureBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One seasonal closure bundle, with what the planners need to act on it.
    final class SeasonalClosureBundle {
        var code: String
        var label: String
        var rate: Double
        var amount: Double
        var budget: Double
        var category: String
        var copay: Double
        var status: SeasonalClosureBundleStatus

        init(code: String, label: String, rate: Double, amount: Double, budget: Double, category: String, copay: Double, status: SeasonalClosureBundleStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.amount = amount
            self.budget = budget
            self.category = category
            self.copay = copay
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

        func canMoveTo(_ next: SeasonalClosureBundleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == SeasonalClosureBundleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalClosureBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal closure bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedValue() -> Double {
            return ((rate - amount) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalClosureBundle {
            return SeasonalClosureBundle(
                code: code,
                label: label,
                rate: rate,
                amount: amount,
                budget: budget,
                category: category,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal closure bundle in status created.
    static func newSeasonalClosureBundle(_ code: String, label: String) -> SeasonalClosureBundle {
        return SeasonalClosureBundle(
            code: code,
            label: label,
            rate: 0.0,
            amount: 0.0,
            budget: 0.0,
            category: "",
            copay: 0.0,
            status: SeasonalClosureBundleStatus.created
        )
    }
}
