import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal substitution variance is in its life cycle.
    enum SeasonalSubstitutionVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal substitution variance as the substitution team keeps it.
    final class SeasonalSubstitutionVariance {
        var code: String
        var name: String
        var diagnosisCode: String
        var cost: Double
        var capacity: Int
        var margin: Double
        var budget: Double
        var status: SeasonalSubstitutionVarianceStatus

        init(code: String, name: String, diagnosisCode: String, cost: Double, capacity: Int, margin: Double, budget: Double, status: SeasonalSubstitutionVarianceStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.cost = cost
            self.capacity = capacity
            self.margin = margin
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalSubstitutionVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalSubstitutionVarianceStatus.withdrawn
            case .approved:
                return next == SeasonalSubstitutionVarianceStatus.rejected || next == SeasonalSubstitutionVarianceStatus.withdrawn
            case .rejected:
                return next == SeasonalSubstitutionVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalSubstitutionVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal substitution variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return (Double(capacity) * cost * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSubstitutionVariance {
            return SeasonalSubstitutionVariance(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                cost: cost,
                capacity: capacity,
                margin: margin,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal substitution variance in status proposed.
    static func newSeasonalSubstitutionVariance(_ code: String, name: String) -> SeasonalSubstitutionVariance {
        return SeasonalSubstitutionVariance(
            code: code,
            name: name,
            diagnosisCode: "",
            cost: 0.0,
            capacity: 0,
            margin: 0.0,
            budget: 0.0,
            status: SeasonalSubstitutionVarianceStatus.proposed
        )
    }
}
