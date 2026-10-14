import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered proxy budget is in its life cycle.
    enum TieredProxyBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a tiered proxy budget and its current status.
    final class TieredProxyBudget {
        var code: String
        var label: String
        var margin: Double
        var clinicianID: String
        var dosageMg: Double
        var rate: Double
        var category: String
        var bed: String
        var budget: Double
        var revision: Int
        var tags: [String]
        var status: TieredProxyBudgetStatus

        init(code: String, label: String, margin: Double, clinicianID: String, dosageMg: Double, rate: Double, category: String, bed: String, budget: Double, revision: Int, tags: [String], status: TieredProxyBudgetStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.clinicianID = clinicianID
            self.dosageMg = dosageMg
            self.rate = rate
            self.category = category
            self.bed = bed
            self.budget = budget
            self.revision = revision
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredProxyBudgetStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredProxyBudgetStatus.revoked
            case .granted:
                return next == TieredProxyBudgetStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: TieredProxyBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered proxy budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("tiered proxy budget") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return ((budget - rate) * 100).rounded() / 100
        }

        func copyValue() -> TieredProxyBudget {
            return TieredProxyBudget(
                code: code,
                label: label,
                margin: margin,
                clinicianID: clinicianID,
                dosageMg: dosageMg,
                rate: rate,
                category: category,
                bed: bed,
                budget: budget,
                revision: revision,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered proxy budget in status requested.
    static func newTieredProxyBudget(_ code: String, label: String) -> TieredProxyBudget {
        return TieredProxyBudget(
            code: code,
            label: label,
            margin: 0.0,
            clinicianID: "",
            dosageMg: 0.0,
            rate: 0.0,
            category: "",
            bed: "",
            budget: 0.0,
            revision: 0,
            tags: [],
            status: TieredProxyBudgetStatus.requested
        )
    }
}
