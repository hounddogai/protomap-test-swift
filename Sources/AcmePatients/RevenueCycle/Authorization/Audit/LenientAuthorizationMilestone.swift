import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient authorization milestone is in its life cycle.
    enum LenientAuthorizationMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One lenient authorization milestone, with what the planners need to act on it.
    final class LenientAuthorizationMilestone {
        var code: String
        var label: String
        var currency: String
        var minimum: Double
        var attributes: [String: String]
        var endsAt: Int
        var expiresAt: Int
        var score: Double
        var status: LenientAuthorizationMilestoneStatus

        init(code: String, label: String, currency: String, minimum: Double, attributes: [String: String], endsAt: Int, expiresAt: Int, score: Double, status: LenientAuthorizationMilestoneStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.minimum = minimum
            self.attributes = attributes
            self.endsAt = endsAt
            self.expiresAt = expiresAt
            self.score = score
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

        func canMoveTo(_ next: LenientAuthorizationMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientAuthorizationMilestoneStatus.draining || next == LenientAuthorizationMilestoneStatus.stopped
            case .warming:
                return next == LenientAuthorizationMilestoneStatus.ready || next == LenientAuthorizationMilestoneStatus.stopped
            case .ready:
                return next == LenientAuthorizationMilestoneStatus.stopped
            case .draining:
                return next == LenientAuthorizationMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientAuthorizationMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient authorization milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("lenient authorization milestone") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedTotal() -> Double {
            return (minimum * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> LenientAuthorizationMilestone {
            return LenientAuthorizationMilestone(
                code: code,
                label: label,
                currency: currency,
                minimum: minimum,
                attributes: attributes,
                endsAt: endsAt,
                expiresAt: expiresAt,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient authorization milestone in status idle.
    static func newLenientAuthorizationMilestone(_ code: String, label: String) -> LenientAuthorizationMilestone {
        return LenientAuthorizationMilestone(
            code: code,
            label: label,
            currency: "",
            minimum: 0.0,
            attributes: [:],
            endsAt: 0,
            expiresAt: 0,
            score: 0.0,
            status: LenientAuthorizationMilestoneStatus.idle
        )
    }
}
