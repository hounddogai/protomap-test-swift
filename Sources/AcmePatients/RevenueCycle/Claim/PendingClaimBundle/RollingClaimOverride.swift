import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling claim override is in its life cycle.
    enum RollingClaimOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling claim override. Its code is unique within a tenant.
    final class RollingClaimOverride {
        var code: String
        var title: String
        var active: Bool
        var archived: Bool
        var channel: String
        var payer: String
        var encounterID: String
        var score: Double
        var status: RollingClaimOverrideStatus

        init(code: String, title: String, active: Bool, archived: Bool, channel: String, payer: String, encounterID: String, score: Double, status: RollingClaimOverrideStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.archived = archived
            self.channel = channel
            self.payer = payer
            self.encounterID = encounterID
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingClaimOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingClaimOverrideStatus.running
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RollingClaimOverrideStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RollingClaimOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling claim override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> RollingClaimOverride {
            return RollingClaimOverride(
                code: code,
                title: title,
                active: active,
                archived: archived,
                channel: channel,
                payer: payer,
                encounterID: encounterID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling claim override in status new.
    static func newRollingClaimOverride(_ code: String, title: String) -> RollingClaimOverride {
        return RollingClaimOverride(
            code: code,
            title: title,
            active: false,
            archived: false,
            channel: "",
            payer: "",
            encounterID: "",
            score: 0.0,
            status: RollingClaimOverrideStatus.new
        )
    }
}
