import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive credential rule is in its life cycle.
    enum AdaptiveCredentialRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A adaptive credential rule. Its code is unique within a tenant.
    final class AdaptiveCredentialRule {
        var code: String
        var label: String
        var createdAt: Int
        var retries: Int
        var approved: Bool
        var status: AdaptiveCredentialRuleStatus

        init(code: String, label: String, createdAt: Int, retries: Int, approved: Bool, status: AdaptiveCredentialRuleStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.retries = retries
            self.approved = approved
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

        func canMoveTo(_ next: AdaptiveCredentialRuleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AdaptiveCredentialRuleStatus.ready || next == AdaptiveCredentialRuleStatus.stopped
            case .ready:
                return next == AdaptiveCredentialRuleStatus.draining
            case .draining:
                return next == AdaptiveCredentialRuleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCredentialRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive credential rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive credential rule") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(createdAt) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCredentialRule {
            return AdaptiveCredentialRule(
                code: code,
                label: label,
                createdAt: createdAt,
                retries: retries,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive credential rule in status idle.
    static func newAdaptiveCredentialRule(_ code: String, label: String) -> AdaptiveCredentialRule {
        return AdaptiveCredentialRule(
            code: code,
            label: label,
            createdAt: 0,
            retries: 0,
            approved: false,
            status: AdaptiveCredentialRuleStatus.idle
        )
    }
}
