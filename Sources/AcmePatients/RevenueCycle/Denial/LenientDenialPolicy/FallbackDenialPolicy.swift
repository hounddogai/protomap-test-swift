import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback denial policy is in its life cycle.
    enum FallbackDenialPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a fallback denial policy and its current status.
    final class FallbackDenialPolicy {
        var code: String
        var title: String
        var unit: String
        var source: String
        var summary: String
        var attempts: Int
        var score: Double
        var status: FallbackDenialPolicyStatus

        init(code: String, title: String, unit: String, source: String, summary: String, attempts: Int, score: Double, status: FallbackDenialPolicyStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.source = source
            self.summary = summary
            self.attempts = attempts
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackDenialPolicyStatus) -> Bool {
            switch status {
            case .created:
                return next == FallbackDenialPolicyStatus.published
            case .validated:
                return next == FallbackDenialPolicyStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: FallbackDenialPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback denial policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netExposure() -> Double {
            return (Double(attempts) * score * 100).rounded() / 100
        }

        func copyValue() -> FallbackDenialPolicy {
            return FallbackDenialPolicy(
                code: code,
                title: title,
                unit: unit,
                source: source,
                summary: summary,
                attempts: attempts,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a fallback denial policy in status created.
    static func newFallbackDenialPolicy(_ code: String, title: String) -> FallbackDenialPolicy {
        return FallbackDenialPolicy(
            code: code,
            title: title,
            unit: "",
            source: "",
            summary: "",
            attempts: 0,
            score: 0.0,
            status: FallbackDenialPolicyStatus.created
        )
    }
}
