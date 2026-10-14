import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal risk score policy is in its life cycle.
    enum SeasonalRiskScorePolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a seasonal risk score policy and its current status.
    final class SeasonalRiskScorePolicy {
        var code: String
        var name: String
        var copay: Double
        var ceiling: Double
        var score: Double
        var attributes: [String: String]
        var country: String
        var procedureCode: String
        var revision: Int
        var status: SeasonalRiskScorePolicyStatus

        init(code: String, name: String, copay: Double, ceiling: Double, score: Double, attributes: [String: String], country: String, procedureCode: String, revision: Int, status: SeasonalRiskScorePolicyStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.ceiling = ceiling
            self.score = score
            self.attributes = attributes
            self.country = country
            self.procedureCode = procedureCode
            self.revision = revision
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

        func canMoveTo(_ next: SeasonalRiskScorePolicyStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalRiskScorePolicyStatus.published || next == SeasonalRiskScorePolicyStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SeasonalRiskScorePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal risk score policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func weightedTotal() -> Double {
            return (copay * score * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRiskScorePolicy {
            return SeasonalRiskScorePolicy(
                code: code,
                name: name,
                copay: copay,
                ceiling: ceiling,
                score: score,
                attributes: attributes,
                country: country,
                procedureCode: procedureCode,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a seasonal risk score policy in status created.
    static func newSeasonalRiskScorePolicy(_ code: String, name: String) -> SeasonalRiskScorePolicy {
        return SeasonalRiskScorePolicy(
            code: code,
            name: name,
            copay: 0.0,
            ceiling: 0.0,
            score: 0.0,
            attributes: [:],
            country: "",
            procedureCode: "",
            revision: 0,
            status: SeasonalRiskScorePolicyStatus.created
        )
    }
}
