import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive study manifest is in its life cycle.
    enum AdaptiveStudyManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One adaptive study manifest, with what the planners need to act on it.
    final class AdaptiveStudyManifest {
        var code: String
        var label: String
        var currency: String
        var threshold: Double
        var minimum: Double
        var active: Bool
        var summary: String
        var startsAt: Int
        var amount: Double
        var ceiling: Double
        var status: AdaptiveStudyManifestStatus

        init(code: String, label: String, currency: String, threshold: Double, minimum: Double, active: Bool, summary: String, startsAt: Int, amount: Double, ceiling: Double, status: AdaptiveStudyManifestStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.threshold = threshold
            self.minimum = minimum
            self.active = active
            self.summary = summary
            self.startsAt = startsAt
            self.amount = amount
            self.ceiling = ceiling
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

        func canMoveTo(_ next: AdaptiveStudyManifestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveStudyManifestStatus.inReview || next == AdaptiveStudyManifestStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AdaptiveStudyManifestStatus.reopened
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

        func moveTo(_ next: AdaptiveStudyManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive study manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return (threshold * minimum * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveStudyManifest {
            return AdaptiveStudyManifest(
                code: code,
                label: label,
                currency: currency,
                threshold: threshold,
                minimum: minimum,
                active: active,
                summary: summary,
                startsAt: startsAt,
                amount: amount,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive study manifest in status open.
    static func newAdaptiveStudyManifest(_ code: String, label: String) -> AdaptiveStudyManifest {
        return AdaptiveStudyManifest(
            code: code,
            label: label,
            currency: "",
            threshold: 0.0,
            minimum: 0.0,
            active: false,
            summary: "",
            startsAt: 0,
            amount: 0.0,
            ceiling: 0.0,
            status: AdaptiveStudyManifestStatus.`open`
        )
    }
}
