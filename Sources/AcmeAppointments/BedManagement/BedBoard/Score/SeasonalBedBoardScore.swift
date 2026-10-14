import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal bed board score is in its life cycle.
    enum SeasonalBedBoardScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A seasonal bed board score as the bed board team keeps it.
    final class SeasonalBedBoardScore {
        var code: String
        var title: String
        var windowDays: Int
        var maximum: Double
        var attributes: [String: String]
        var status: SeasonalBedBoardScoreStatus

        init(code: String, title: String, windowDays: Int, maximum: Double, attributes: [String: String], status: SeasonalBedBoardScoreStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.maximum = maximum
            self.attributes = attributes
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

        func canMoveTo(_ next: SeasonalBedBoardScoreStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalBedBoardScoreStatus.inProgress
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == SeasonalBedBoardScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalBedBoardScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal bed board score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal bed board score") \(code)"
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

        func projectedValue() -> Double {
            return ((maximum - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalBedBoardScore {
            return SeasonalBedBoardScore(
                code: code,
                title: title,
                windowDays: windowDays,
                maximum: maximum,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal bed board score in status planned.
    static func newSeasonalBedBoardScore(_ code: String, title: String) -> SeasonalBedBoardScore {
        return SeasonalBedBoardScore(
            code: code,
            title: title,
            windowDays: 0,
            maximum: 0.0,
            attributes: [:],
            status: SeasonalBedBoardScoreStatus.planned
        )
    }
}
