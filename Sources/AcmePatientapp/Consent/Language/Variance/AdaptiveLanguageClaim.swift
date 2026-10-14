import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive language claim is in its life cycle.
    enum AdaptiveLanguageClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive language claim as the language team keeps it.
    final class AdaptiveLanguageClaim {
        var code: String
        var label: String
        var endsAt: Int
        var discount: Double
        var region: String
        var status: AdaptiveLanguageClaimStatus

        init(code: String, label: String, endsAt: Int, discount: Double, region: String, status: AdaptiveLanguageClaimStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.discount = discount
            self.region = region
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

        func canMoveTo(_ next: AdaptiveLanguageClaimStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveLanguageClaimStatus.resolved || next == AdaptiveLanguageClaimStatus.reopened
            case .resolved:
                return next == AdaptiveLanguageClaimStatus.reopened || next == AdaptiveLanguageClaimStatus.archived
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

        func moveTo(_ next: AdaptiveLanguageClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive language claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive language claim") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((discount - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveLanguageClaim {
            return AdaptiveLanguageClaim(
                code: code,
                label: label,
                endsAt: endsAt,
                discount: discount,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a adaptive language claim in status open.
    static func newAdaptiveLanguageClaim(_ code: String, label: String) -> AdaptiveLanguageClaim {
        return AdaptiveLanguageClaim(
            code: code,
            label: label,
            endsAt: 0,
            discount: 0.0,
            region: "",
            status: AdaptiveLanguageClaimStatus.`open`
        )
    }
}
