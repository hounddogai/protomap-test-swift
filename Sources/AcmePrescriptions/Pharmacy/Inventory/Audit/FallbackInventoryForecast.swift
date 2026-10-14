import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback inventory forecast is in its life cycle.
    enum FallbackInventoryForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One fallback inventory forecast, with what the planners need to act on it.
    final class FallbackInventoryForecast {
        var code: String
        var name: String
        var score: Double
        var reviewer: String
        var patientRef: String
        var cost: Double
        var archived: Bool
        var region: String
        var status: FallbackInventoryForecastStatus

        init(code: String, name: String, score: Double, reviewer: String, patientRef: String, cost: Double, archived: Bool, region: String, status: FallbackInventoryForecastStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.reviewer = reviewer
            self.patientRef = patientRef
            self.cost = cost
            self.archived = archived
            self.region = region
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

        func canMoveTo(_ next: FallbackInventoryForecastStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FallbackInventoryForecastStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FallbackInventoryForecastStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackInventoryForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback inventory forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback inventory forecast") \(code)"
        }

        func netVolume() -> Double {
            return ((cost - score) * 100).rounded() / 100
        }

        func copyValue() -> FallbackInventoryForecast {
            return FallbackInventoryForecast(
                code: code,
                name: name,
                score: score,
                reviewer: reviewer,
                patientRef: patientRef,
                cost: cost,
                archived: archived,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback inventory forecast in status planned.
    static func newFallbackInventoryForecast(_ code: String, name: String) -> FallbackInventoryForecast {
        return FallbackInventoryForecast(
            code: code,
            name: name,
            score: 0.0,
            reviewer: "",
            patientRef: "",
            cost: 0.0,
            archived: false,
            region: "",
            status: FallbackInventoryForecastStatus.planned
        )
    }
}
