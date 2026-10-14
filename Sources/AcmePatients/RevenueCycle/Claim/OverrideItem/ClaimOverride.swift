import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim override is in its life cycle.
    enum ClaimOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a claim override and its current status.
    final class ClaimOverride {
        var code: String
        var label: String
        var weight: Double
        var visitMinutes: Int
        var endsAt: Int
        var summary: String
        var expiresAt: Int
        var reviewer: String
        var currency: String
        var status: ClaimOverrideStatus

        init(code: String, label: String, weight: Double, visitMinutes: Int, endsAt: Int, summary: String, expiresAt: Int, reviewer: String, currency: String, status: ClaimOverrideStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.visitMinutes = visitMinutes
            self.endsAt = endsAt
            self.summary = summary
            self.expiresAt = expiresAt
            self.reviewer = reviewer
            self.currency = currency
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

        func canMoveTo(_ next: ClaimOverrideStatus) -> Bool {
            switch status {
            case .idle:
                return next == ClaimOverrideStatus.stopped
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ClaimOverrideStatus.stopped
            case .draining:
                return next == ClaimOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedValue() -> Double {
            return ((Double(endsAt) + weight) * 100).rounded() / 100
        }

        func copyValue() -> ClaimOverride {
            return ClaimOverride(
                code: code,
                label: label,
                weight: weight,
                visitMinutes: visitMinutes,
                endsAt: endsAt,
                summary: summary,
                expiresAt: expiresAt,
                reviewer: reviewer,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a claim override in status idle.
    static func newClaimOverride(_ code: String, label: String) -> ClaimOverride {
        return ClaimOverride(
            code: code,
            label: label,
            weight: 0.0,
            visitMinutes: 0,
            endsAt: 0,
            summary: "",
            expiresAt: 0,
            reviewer: "",
            currency: "",
            status: ClaimOverrideStatus.idle
        )
    }
}
