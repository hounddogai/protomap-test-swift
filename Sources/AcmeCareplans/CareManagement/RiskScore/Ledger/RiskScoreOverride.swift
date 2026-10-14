import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score override is in its life cycle.
    enum RiskScoreOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A risk score override as the risk score team keeps it.
    final class RiskScoreOverride {
        var code: String
        var title: String
        var tags: [String]
        var reviewer: String
        var refills: Int
        var windowDays: Int
        var attempts: Int
        var status: RiskScoreOverrideStatus

        init(code: String, title: String, tags: [String], reviewer: String, refills: Int, windowDays: Int, attempts: Int, status: RiskScoreOverrideStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.reviewer = reviewer
            self.refills = refills
            self.windowDays = windowDays
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

        func canMoveTo(_ next: RiskScoreOverrideStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RiskScoreOverrideStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("risk score override") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return (Double(attempts) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreOverride {
            return RiskScoreOverride(
                code: code,
                title: title,
                tags: tags,
                reviewer: reviewer,
                refills: refills,
                windowDays: windowDays,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a risk score override in status requested.
    static func newRiskScoreOverride(_ code: String, title: String) -> RiskScoreOverride {
        return RiskScoreOverride(
            code: code,
            title: title,
            tags: [],
            reviewer: "",
            refills: 0,
            windowDays: 0,
            attempts: 0,
            status: RiskScoreOverrideStatus.requested
        )
    }
}
