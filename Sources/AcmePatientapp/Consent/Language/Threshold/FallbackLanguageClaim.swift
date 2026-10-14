import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback language claim is in its life cycle.
    enum FallbackLanguageClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a fallback language claim and its current status.
    final class FallbackLanguageClaim {
        var code: String
        var label: String
        var amount: Double
        var segment: String
        var dosageMg: Double
        var summary: String
        var status: FallbackLanguageClaimStatus

        init(code: String, label: String, amount: Double, segment: String, dosageMg: Double, summary: String, status: FallbackLanguageClaimStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.segment = segment
            self.dosageMg = dosageMg
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackLanguageClaimStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackLanguageClaimStatus.ready || next == FallbackLanguageClaimStatus.stopped
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FallbackLanguageClaimStatus.draining || next == FallbackLanguageClaimStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: FallbackLanguageClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback language claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return (dosageMg * amount * 100).rounded() / 100
        }

        func copyValue() -> FallbackLanguageClaim {
            return FallbackLanguageClaim(
                code: code,
                label: label,
                amount: amount,
                segment: segment,
                dosageMg: dosageMg,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback language claim in status idle.
    static func newFallbackLanguageClaim(_ code: String, label: String) -> FallbackLanguageClaim {
        return FallbackLanguageClaim(
            code: code,
            label: label,
            amount: 0.0,
            segment: "",
            dosageMg: 0.0,
            summary: "",
            status: FallbackLanguageClaimStatus.idle
        )
    }
}
