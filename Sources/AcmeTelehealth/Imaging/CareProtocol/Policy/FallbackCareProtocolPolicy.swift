import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback care protocol policy is in its life cycle.
    enum FallbackCareProtocolPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a fallback care protocol policy and its current status.
    final class FallbackCareProtocolPolicy {
        var code: String
        var title: String
        var payer: String
        var specialty: String
        var threshold: Double
        var graceDays: Int
        var status: FallbackCareProtocolPolicyStatus

        init(code: String, title: String, payer: String, specialty: String, threshold: Double, graceDays: Int, status: FallbackCareProtocolPolicyStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.specialty = specialty
            self.threshold = threshold
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackCareProtocolPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackCareProtocolPolicyStatus.active || next == FallbackCareProtocolPolicyStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == FallbackCareProtocolPolicyStatus.suspended || next == FallbackCareProtocolPolicyStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: FallbackCareProtocolPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care protocol policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return ((Double(graceDays) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCareProtocolPolicy {
            return FallbackCareProtocolPolicy(
                code: code,
                title: title,
                payer: payer,
                specialty: specialty,
                threshold: threshold,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback care protocol policy in status draft.
    static func newFallbackCareProtocolPolicy(_ code: String, title: String) -> FallbackCareProtocolPolicy {
        return FallbackCareProtocolPolicy(
            code: code,
            title: title,
            payer: "",
            specialty: "",
            threshold: 0.0,
            graceDays: 0,
            status: FallbackCareProtocolPolicyStatus.draft
        )
    }
}
