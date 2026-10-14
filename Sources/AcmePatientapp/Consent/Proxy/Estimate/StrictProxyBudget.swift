import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict proxy budget is in its life cycle.
    enum StrictProxyBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict proxy budget as the proxy team keeps it.
    final class StrictProxyBudget {
        var code: String
        var title: String
        var score: Double
        var encounterID: String
        var phone: String
        var capacity: Int
        var budget: Double
        var weight: Double
        var updatedAt: Int
        var discount: Double
        var expiresAt: Int
        var status: StrictProxyBudgetStatus

        init(code: String, title: String, score: Double, encounterID: String, phone: String, capacity: Int, budget: Double, weight: Double, updatedAt: Int, discount: Double, expiresAt: Int, status: StrictProxyBudgetStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.encounterID = encounterID
            self.phone = phone
            self.capacity = capacity
            self.budget = budget
            self.weight = weight
            self.updatedAt = updatedAt
            self.discount = discount
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: StrictProxyBudgetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == StrictProxyBudgetStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == StrictProxyBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictProxyBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict proxy budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedValue() -> Double {
            return (Double(expiresAt) * weight * 100).rounded() / 100
        }

        func copyValue() -> StrictProxyBudget {
            return StrictProxyBudget(
                code: code,
                title: title,
                score: score,
                encounterID: encounterID,
                phone: phone,
                capacity: capacity,
                budget: budget,
                weight: weight,
                updatedAt: updatedAt,
                discount: discount,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict proxy budget in status new.
    static func newStrictProxyBudget(_ code: String, title: String) -> StrictProxyBudget {
        return StrictProxyBudget(
            code: code,
            title: title,
            score: 0.0,
            encounterID: "",
            phone: "",
            capacity: 0,
            budget: 0.0,
            weight: 0.0,
            updatedAt: 0,
            discount: 0.0,
            expiresAt: 0,
            status: StrictProxyBudgetStatus.new
        )
    }
}
