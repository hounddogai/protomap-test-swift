import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional substitution forecast is in its life cycle.
    enum RegionalSubstitutionForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional substitution forecast. Its code is unique within a tenant.
    final class RegionalSubstitutionForecast {
        var code: String
        var name: String
        var threshold: Double
        var attempts: Int
        var sequence: Int
        var dosageMg: Double
        var tags: [String]
        var allergy: String
        var batchSize: Int
        var notes: String
        var maximum: Double
        var status: RegionalSubstitutionForecastStatus

        init(code: String, name: String, threshold: Double, attempts: Int, sequence: Int, dosageMg: Double, tags: [String], allergy: String, batchSize: Int, notes: String, maximum: Double, status: RegionalSubstitutionForecastStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.attempts = attempts
            self.sequence = sequence
            self.dosageMg = dosageMg
            self.tags = tags
            self.allergy = allergy
            self.batchSize = batchSize
            self.notes = notes
            self.maximum = maximum
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

        func canMoveTo(_ next: RegionalSubstitutionForecastStatus) -> Bool {
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
                return next == RegionalSubstitutionForecastStatus.completed || next == RegionalSubstitutionForecastStatus.cancelled
            case .inProgress:
                return next == RegionalSubstitutionForecastStatus.completed || next == RegionalSubstitutionForecastStatus.cancelled
            case .completed:
                return next == RegionalSubstitutionForecastStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalSubstitutionForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional substitution forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((dosageMg + maximum) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSubstitutionForecast {
            return RegionalSubstitutionForecast(
                code: code,
                name: name,
                threshold: threshold,
                attempts: attempts,
                sequence: sequence,
                dosageMg: dosageMg,
                tags: tags,
                allergy: allergy,
                batchSize: batchSize,
                notes: notes,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional substitution forecast in status planned.
    static func newRegionalSubstitutionForecast(_ code: String, name: String) -> RegionalSubstitutionForecast {
        return RegionalSubstitutionForecast(
            code: code,
            name: name,
            threshold: 0.0,
            attempts: 0,
            sequence: 0,
            dosageMg: 0.0,
            tags: [],
            allergy: "",
            batchSize: 0,
            notes: "",
            maximum: 0.0,
            status: RegionalSubstitutionForecastStatus.planned
        )
    }
}
