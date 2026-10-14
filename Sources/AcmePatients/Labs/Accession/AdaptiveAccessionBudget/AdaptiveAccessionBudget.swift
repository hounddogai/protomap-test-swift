import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive accession budget is in its life cycle.
    enum AdaptiveAccessionBudgetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a adaptive accession budget and its current status.
    final class AdaptiveAccessionBudget {
        var code: String
        var name: String
        var procedureCode: String
        var specialty: String
        var maximum: Double
        var notes: String
        var weight: Double
        var retries: Int
        var country: String
        var copay: Double
        var status: AdaptiveAccessionBudgetStatus

        init(code: String, name: String, procedureCode: String, specialty: String, maximum: Double, notes: String, weight: Double, retries: Int, country: String, copay: Double, status: AdaptiveAccessionBudgetStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.maximum = maximum
            self.notes = notes
            self.weight = weight
            self.retries = retries
            self.country = country
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

        func canMoveTo(_ next: AdaptiveAccessionBudgetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AdaptiveAccessionBudgetStatus.published || next == AdaptiveAccessionBudgetStatus.retired
            case .published:
                return next == AdaptiveAccessionBudgetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveAccessionBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive accession budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedTotal() -> Double {
            return ((copay - maximum) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAccessionBudget {
            return AdaptiveAccessionBudget(
                code: code,
                name: name,
                procedureCode: procedureCode,
                specialty: specialty,
                maximum: maximum,
                notes: notes,
                weight: weight,
                retries: retries,
                country: country,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive accession budget in status created.
    static func newAdaptiveAccessionBudget(_ code: String, name: String) -> AdaptiveAccessionBudget {
        return AdaptiveAccessionBudget(
            code: code,
            name: name,
            procedureCode: "",
            specialty: "",
            maximum: 0.0,
            notes: "",
            weight: 0.0,
            retries: 0,
            country: "",
            copay: 0.0,
            status: AdaptiveAccessionBudgetStatus.created
        )
    }
}
