import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal eligibility estimate is in its life cycle.
    enum SeasonalEligibilityEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a seasonal eligibility estimate and its current status.
    final class SeasonalEligibilityEstimate {
        var code: String
        var title: String
        var label: String
        var attributes: [String: String]
        var startsAt: Int
        var limit: Int
        var status: SeasonalEligibilityEstimateStatus

        init(code: String, title: String, label: String, attributes: [String: String], startsAt: Int, limit: Int, status: SeasonalEligibilityEstimateStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.attributes = attributes
            self.startsAt = startsAt
            self.limit = limit
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

        func canMoveTo(_ next: SeasonalEligibilityEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == SeasonalEligibilityEstimateStatus.archived
            case .resolved:
                return next == SeasonalEligibilityEstimateStatus.reopened
            case .reopened:
                return next == SeasonalEligibilityEstimateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalEligibilityEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal eligibility estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
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

        func effectiveValue() -> Double {
            return ((Double(startsAt) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalEligibilityEstimate {
            return SeasonalEligibilityEstimate(
                code: code,
                title: title,
                label: label,
                attributes: attributes,
                startsAt: startsAt,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal eligibility estimate in status open.
    static func newSeasonalEligibilityEstimate(_ code: String, title: String) -> SeasonalEligibilityEstimate {
        return SeasonalEligibilityEstimate(
            code: code,
            title: title,
            label: "",
            attributes: [:],
            startsAt: 0,
            limit: 0,
            status: SeasonalEligibilityEstimateStatus.`open`
        )
    }
}
