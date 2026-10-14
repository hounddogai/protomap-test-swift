import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback program variance is in its life cycle.
    enum FallbackProgramVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback program variance. Its code is unique within a tenant.
    final class FallbackProgramVariance {
        var code: String
        var title: String
        var threshold: Double
        var margin: Double
        var copay: Double
        var status: FallbackProgramVarianceStatus

        init(code: String, title: String, threshold: Double, margin: Double, copay: Double, status: FallbackProgramVarianceStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.margin = margin
            self.copay = copay
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

        func canMoveTo(_ next: FallbackProgramVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackProgramVarianceStatus.inReview || next == FallbackProgramVarianceStatus.resolved
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FallbackProgramVarianceStatus.archived
            case .reopened:
                return next == FallbackProgramVarianceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackProgramVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback program variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netExposure() -> Double {
            return ((copay + threshold) * 100).rounded() / 100
        }

        func copyValue() -> FallbackProgramVariance {
            return FallbackProgramVariance(
                code: code,
                title: title,
                threshold: threshold,
                margin: margin,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback program variance in status open.
    static func newFallbackProgramVariance(_ code: String, title: String) -> FallbackProgramVariance {
        return FallbackProgramVariance(
            code: code,
            title: title,
            threshold: 0.0,
            margin: 0.0,
            copay: 0.0,
            status: FallbackProgramVarianceStatus.`open`
        )
    }
}
