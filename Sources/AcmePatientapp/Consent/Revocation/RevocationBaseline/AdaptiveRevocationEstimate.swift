import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive revocation estimate is in its life cycle.
    enum AdaptiveRevocationEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive revocation estimate. Its code is unique within a tenant.
    final class AdaptiveRevocationEstimate {
        var code: String
        var title: String
        var priority: Int
        var updatedAt: Int
        var windowDays: Int
        var currency: String
        var ceiling: Double
        var externalRef: String
        var copay: Double
        var threshold: Double
        var status: AdaptiveRevocationEstimateStatus

        init(code: String, title: String, priority: Int, updatedAt: Int, windowDays: Int, currency: String, ceiling: Double, externalRef: String, copay: Double, threshold: Double, status: AdaptiveRevocationEstimateStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.updatedAt = updatedAt
            self.windowDays = windowDays
            self.currency = currency
            self.ceiling = ceiling
            self.externalRef = externalRef
            self.copay = copay
            self.threshold = threshold
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

        func canMoveTo(_ next: AdaptiveRevocationEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveRevocationEstimateStatus.inReview || next == AdaptiveRevocationEstimateStatus.resolved
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AdaptiveRevocationEstimateStatus.reopened
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

        func moveTo(_ next: AdaptiveRevocationEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive revocation estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive revocation estimate") \(code)"
        }

        func weightedExposure() -> Double {
            return ((threshold + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRevocationEstimate {
            return AdaptiveRevocationEstimate(
                code: code,
                title: title,
                priority: priority,
                updatedAt: updatedAt,
                windowDays: windowDays,
                currency: currency,
                ceiling: ceiling,
                externalRef: externalRef,
                copay: copay,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive revocation estimate in status open.
    static func newAdaptiveRevocationEstimate(_ code: String, title: String) -> AdaptiveRevocationEstimate {
        return AdaptiveRevocationEstimate(
            code: code,
            title: title,
            priority: 0,
            updatedAt: 0,
            windowDays: 0,
            currency: "",
            ceiling: 0.0,
            externalRef: "",
            copay: 0.0,
            threshold: 0.0,
            status: AdaptiveRevocationEstimateStatus.`open`
        )
    }
}
