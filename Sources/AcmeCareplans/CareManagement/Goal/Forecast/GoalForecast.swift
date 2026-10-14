import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal forecast is in its life cycle.
    enum GoalForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One goal forecast, with what the planners need to act on it.
    final class GoalForecast {
        var code: String
        var title: String
        var summary: String
        var attributes: [String: String]
        var archived: Bool
        var discount: Double
        var status: GoalForecastStatus

        init(code: String, title: String, summary: String, attributes: [String: String], archived: Bool, discount: Double, status: GoalForecastStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.attributes = attributes
            self.archived = archived
            self.discount = discount
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

        func canMoveTo(_ next: GoalForecastStatus) -> Bool {
            switch status {
            case .created:
                return next == GoalForecastStatus.published
            case .validated:
                return next == GoalForecastStatus.published
            case .published:
                return next == GoalForecastStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("goal forecast") \(code)"
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

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> GoalForecast {
            return GoalForecast(
                code: code,
                title: title,
                summary: summary,
                attributes: attributes,
                archived: archived,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a goal forecast in status created.
    static func newGoalForecast(_ code: String, title: String) -> GoalForecast {
        return GoalForecast(
            code: code,
            title: title,
            summary: "",
            attributes: [:],
            archived: false,
            discount: 0.0,
            status: GoalForecastStatus.created
        )
    }
}
