import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy study score is in its life cycle.
    enum LegacyStudyScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One legacy study score, with what the planners need to act on it.
    final class LegacyStudyScore {
        var code: String
        var label: String
        var description: String
        var budget: Double
        var attributes: [String: String]
        var rate: Double
        var status: LegacyStudyScoreStatus

        init(code: String, label: String, description: String, budget: Double, attributes: [String: String], rate: Double, status: LegacyStudyScoreStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.budget = budget
            self.attributes = attributes
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyStudyScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyStudyScoreStatus.resolved
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyStudyScoreStatus.reopened || next == LegacyStudyScoreStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LegacyStudyScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy study score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy study score") \(code)"
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

        func weightedValue() -> Double {
            return ((budget - rate) * 100).rounded() / 100
        }

        func copyValue() -> LegacyStudyScore {
            return LegacyStudyScore(
                code: code,
                label: label,
                description: description,
                budget: budget,
                attributes: attributes,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy study score in status open.
    static func newLegacyStudyScore(_ code: String, label: String) -> LegacyStudyScore {
        return LegacyStudyScore(
            code: code,
            label: label,
            description: "",
            budget: 0.0,
            attributes: [:],
            rate: 0.0,
            status: LegacyStudyScoreStatus.`open`
        )
    }
}
