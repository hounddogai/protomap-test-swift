import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive interaction template is in its life cycle.
    enum AdaptiveInteractionTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive interaction template, with what the planners need to act on it.
    final class AdaptiveInteractionTemplate {
        var code: String
        var label: String
        var currency: String
        var expiresAt: Int
        var score: Double
        var pinned: Bool
        var segment: String
        var active: Bool
        var revision: Int
        var endsAt: Int
        var attempts: Int
        var status: AdaptiveInteractionTemplateStatus

        init(code: String, label: String, currency: String, expiresAt: Int, score: Double, pinned: Bool, segment: String, active: Bool, revision: Int, endsAt: Int, attempts: Int, status: AdaptiveInteractionTemplateStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.expiresAt = expiresAt
            self.score = score
            self.pinned = pinned
            self.segment = segment
            self.active = active
            self.revision = revision
            self.endsAt = endsAt
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveInteractionTemplateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AdaptiveInteractionTemplateStatus.revoked || next == AdaptiveInteractionTemplateStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AdaptiveInteractionTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive interaction template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("adaptive interaction template") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(endsAt) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveInteractionTemplate {
            return AdaptiveInteractionTemplate(
                code: code,
                label: label,
                currency: currency,
                expiresAt: expiresAt,
                score: score,
                pinned: pinned,
                segment: segment,
                active: active,
                revision: revision,
                endsAt: endsAt,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive interaction template in status requested.
    static func newAdaptiveInteractionTemplate(_ code: String, label: String) -> AdaptiveInteractionTemplate {
        return AdaptiveInteractionTemplate(
            code: code,
            label: label,
            currency: "",
            expiresAt: 0,
            score: 0.0,
            pinned: false,
            segment: "",
            active: false,
            revision: 0,
            endsAt: 0,
            attempts: 0,
            status: AdaptiveInteractionTemplateStatus.requested
        )
    }
}
