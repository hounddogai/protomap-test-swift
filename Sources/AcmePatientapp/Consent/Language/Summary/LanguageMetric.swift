import AcmePlatform
import Foundation

extension Consent {
    /// Where a language metric is in its life cycle.
    enum LanguageMetricStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One language metric, with what the planners need to act on it.
    final class LanguageMetric {
        var code: String
        var name: String
        var diagnosisCode: String
        var attempts: Int
        var tags: [String]
        var country: String
        var status: LanguageMetricStatus

        init(code: String, name: String, diagnosisCode: String, attempts: Int, tags: [String], country: String, status: LanguageMetricStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.attempts = attempts
            self.tags = tags
            self.country = country
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

        func canMoveTo(_ next: LanguageMetricStatus) -> Bool {
            switch status {
            case .created:
                return next == LanguageMetricStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LanguageMetricStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("language metric") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> LanguageMetric {
            return LanguageMetric(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                attempts: attempts,
                tags: tags,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a language metric in status created.
    static func newLanguageMetric(_ code: String, name: String) -> LanguageMetric {
        return LanguageMetric(
            code: code,
            name: name,
            diagnosisCode: "",
            attempts: 0,
            tags: [],
            country: "",
            status: LanguageMetricStatus.created
        )
    }
}
