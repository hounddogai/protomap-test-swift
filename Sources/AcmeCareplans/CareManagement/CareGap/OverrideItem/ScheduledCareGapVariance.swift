import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled care gap variance is in its life cycle.
    enum ScheduledCareGapVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled care gap variance as the care gap team keeps it.
    final class ScheduledCareGapVariance {
        var code: String
        var name: String
        var locale: String
        var priority: Int
        var allergy: String
        var reviewer: String
        var score: Double
        var limit: Int
        var dosageMg: Double
        var status: ScheduledCareGapVarianceStatus

        init(code: String, name: String, locale: String, priority: Int, allergy: String, reviewer: String, score: Double, limit: Int, dosageMg: Double, status: ScheduledCareGapVarianceStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.priority = priority
            self.allergy = allergy
            self.reviewer = reviewer
            self.score = score
            self.limit = limit
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ScheduledCareGapVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ScheduledCareGapVarianceStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ScheduledCareGapVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care gap variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled care gap variance") \(code)"
        }

        func projectedValue() -> Double {
            return ((score + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCareGapVariance {
            return ScheduledCareGapVariance(
                code: code,
                name: name,
                locale: locale,
                priority: priority,
                allergy: allergy,
                reviewer: reviewer,
                score: score,
                limit: limit,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled care gap variance in status proposed.
    static func newScheduledCareGapVariance(_ code: String, name: String) -> ScheduledCareGapVariance {
        return ScheduledCareGapVariance(
            code: code,
            name: name,
            locale: "",
            priority: 0,
            allergy: "",
            reviewer: "",
            score: 0.0,
            limit: 0,
            dosageMg: 0.0,
            status: ScheduledCareGapVarianceStatus.proposed
        )
    }
}
