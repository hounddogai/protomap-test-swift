import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal witness budget is in its life cycle.
    enum SeasonalWitnessBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One seasonal witness budget, with what the planners need to act on it.
    final class SeasonalWitnessBudget {
        var code: String
        var title: String
        var budget: Double
        var checksum: String
        var cost: Double
        var pinned: Bool
        var approved: Bool
        var source: String
        var currency: String
        var weight: Double
        var status: SeasonalWitnessBudgetStatus

        init(code: String, title: String, budget: Double, checksum: String, cost: Double, pinned: Bool, approved: Bool, source: String, currency: String, weight: Double, status: SeasonalWitnessBudgetStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.checksum = checksum
            self.cost = cost
            self.pinned = pinned
            self.approved = approved
            self.source = source
            self.currency = currency
            self.weight = weight
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

        func canMoveTo(_ next: SeasonalWitnessBudgetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
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
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SeasonalWitnessBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal witness budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal witness budget") \(code)"
        }

        func netTotal() -> Double {
            return ((weight + cost) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalWitnessBudget {
            return SeasonalWitnessBudget(
                code: code,
                title: title,
                budget: budget,
                checksum: checksum,
                cost: cost,
                pinned: pinned,
                approved: approved,
                source: source,
                currency: currency,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a seasonal witness budget in status planned.
    static func newSeasonalWitnessBudget(_ code: String, title: String) -> SeasonalWitnessBudget {
        return SeasonalWitnessBudget(
            code: code,
            title: title,
            budget: 0.0,
            checksum: "",
            cost: 0.0,
            pinned: false,
            approved: false,
            source: "",
            currency: "",
            weight: 0.0,
            status: SeasonalWitnessBudgetStatus.planned
        )
    }
}
