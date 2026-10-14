import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual formulary budget is in its life cycle.
    enum ManualFormularyBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual formulary budget as the formulary team keeps it.
    final class ManualFormularyBudget {
        var code: String
        var title: String
        var capacity: Int
        var cost: Double
        var expiresAt: Int
        var limit: Int
        var attributes: [String: String]
        var category: String
        var description: String
        var rate: Double
        var ceiling: Double
        var status: ManualFormularyBudgetStatus

        init(code: String, title: String, capacity: Int, cost: Double, expiresAt: Int, limit: Int, attributes: [String: String], category: String, description: String, rate: Double, ceiling: Double, status: ManualFormularyBudgetStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.cost = cost
            self.expiresAt = expiresAt
            self.limit = limit
            self.attributes = attributes
            self.category = category
            self.description = description
            self.rate = rate
            self.ceiling = ceiling
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

        func canMoveTo(_ next: ManualFormularyBudgetStatus) -> Bool {
            switch status {
            case .new:
                return next == ManualFormularyBudgetStatus.running
            case .queued:
                return next == ManualFormularyBudgetStatus.running || next == ManualFormularyBudgetStatus.done
            case .running:
                return next == ManualFormularyBudgetStatus.done
            case .done:
                return next == ManualFormularyBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualFormularyBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual formulary budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveVolume() -> Double {
            return (ceiling * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> ManualFormularyBudget {
            return ManualFormularyBudget(
                code: code,
                title: title,
                capacity: capacity,
                cost: cost,
                expiresAt: expiresAt,
                limit: limit,
                attributes: attributes,
                category: category,
                description: description,
                rate: rate,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual formulary budget in status new.
    static func newManualFormularyBudget(_ code: String, title: String) -> ManualFormularyBudget {
        return ManualFormularyBudget(
            code: code,
            title: title,
            capacity: 0,
            cost: 0.0,
            expiresAt: 0,
            limit: 0,
            attributes: [:],
            category: "",
            description: "",
            rate: 0.0,
            ceiling: 0.0,
            status: ManualFormularyBudgetStatus.new
        )
    }
}
