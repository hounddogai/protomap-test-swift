import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered proxy milestone is in its life cycle.
    enum TieredProxyMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One tiered proxy milestone, with what the planners need to act on it.
    final class TieredProxyMilestone {
        var code: String
        var name: String
        var amount: Double
        var ownerID: String
        var attempts: Int
        var batchSize: Int
        var threshold: Double
        var visitMinutes: Int
        var ceiling: Double
        var expiresAt: Int
        var status: TieredProxyMilestoneStatus

        init(code: String, name: String, amount: Double, ownerID: String, attempts: Int, batchSize: Int, threshold: Double, visitMinutes: Int, ceiling: Double, expiresAt: Int, status: TieredProxyMilestoneStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.ownerID = ownerID
            self.attempts = attempts
            self.batchSize = batchSize
            self.threshold = threshold
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: TieredProxyMilestoneStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == TieredProxyMilestoneStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredProxyMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered proxy milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered proxy milestone") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(attempts) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> TieredProxyMilestone {
            return TieredProxyMilestone(
                code: code,
                name: name,
                amount: amount,
                ownerID: ownerID,
                attempts: attempts,
                batchSize: batchSize,
                threshold: threshold,
                visitMinutes: visitMinutes,
                ceiling: ceiling,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered proxy milestone in status new.
    static func newTieredProxyMilestone(_ code: String, name: String) -> TieredProxyMilestone {
        return TieredProxyMilestone(
            code: code,
            name: name,
            amount: 0.0,
            ownerID: "",
            attempts: 0,
            batchSize: 0,
            threshold: 0.0,
            visitMinutes: 0,
            ceiling: 0.0,
            expiresAt: 0,
            status: TieredProxyMilestoneStatus.new
        )
    }
}
