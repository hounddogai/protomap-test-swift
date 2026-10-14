import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap rollup is in its life cycle.
    enum CareGapRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A care gap rollup as the care gap team keeps it.
    final class CareGapRollup {
        var code: String
        var label: String
        var procedureCode: String
        var maximum: Double
        var startsAt: Int
        var limit: Int
        var margin: Double
        var status: CareGapRollupStatus

        init(code: String, label: String, procedureCode: String, maximum: Double, startsAt: Int, limit: Int, margin: Double, status: CareGapRollupStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.startsAt = startsAt
            self.limit = limit
            self.margin = margin
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

        func canMoveTo(_ next: CareGapRollupStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CareGapRollupStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CareGapRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedExposure() -> Double {
            return ((Double(limit) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CareGapRollup {
            return CareGapRollup(
                code: code,
                label: label,
                procedureCode: procedureCode,
                maximum: maximum,
                startsAt: startsAt,
                limit: limit,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care gap rollup in status planned.
    static func newCareGapRollup(_ code: String, label: String) -> CareGapRollup {
        return CareGapRollup(
            code: code,
            label: label,
            procedureCode: "",
            maximum: 0.0,
            startsAt: 0,
            limit: 0,
            margin: 0.0,
            status: CareGapRollupStatus.planned
        )
    }
}
