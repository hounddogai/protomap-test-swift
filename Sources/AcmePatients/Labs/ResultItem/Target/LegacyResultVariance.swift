import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy result variance is in its life cycle.
    enum LegacyResultVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a legacy result variance and its current status.
    final class LegacyResultVariance {
        var code: String
        var title: String
        var category: String
        var expiresAt: Int
        var threshold: Double
        var status: LegacyResultVarianceStatus

        init(code: String, title: String, category: String, expiresAt: Int, threshold: Double, status: LegacyResultVarianceStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.expiresAt = expiresAt
            self.threshold = threshold
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

        func canMoveTo(_ next: LegacyResultVarianceStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyResultVarianceStatus.scheduled || next == LegacyResultVarianceStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LegacyResultVarianceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyResultVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy result variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((Double(expiresAt) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> LegacyResultVariance {
            return LegacyResultVariance(
                code: code,
                title: title,
                category: category,
                expiresAt: expiresAt,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy result variance in status planned.
    static func newLegacyResultVariance(_ code: String, title: String) -> LegacyResultVariance {
        return LegacyResultVariance(
            code: code,
            title: title,
            category: "",
            expiresAt: 0,
            threshold: 0.0,
            status: LegacyResultVarianceStatus.planned
        )
    }
}
