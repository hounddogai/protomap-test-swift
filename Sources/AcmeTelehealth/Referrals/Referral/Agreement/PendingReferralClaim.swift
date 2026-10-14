import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending referral claim is in its life cycle.
    enum PendingReferralClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One pending referral claim, with what the planners need to act on it.
    final class PendingReferralClaim {
        var code: String
        var name: String
        var sequence: Int
        var limit: Int
        var batchSize: Int
        var status: PendingReferralClaimStatus

        init(code: String, name: String, sequence: Int, limit: Int, batchSize: Int, status: PendingReferralClaimStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.limit = limit
            self.batchSize = batchSize
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

        func canMoveTo(_ next: PendingReferralClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingReferralClaimStatus.done
            case .queued:
                return next == PendingReferralClaimStatus.running
            case .running:
                return next == PendingReferralClaimStatus.done || next == PendingReferralClaimStatus.failed
            case .done:
                return next == PendingReferralClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingReferralClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending referral claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedExposure() -> Double {
            return (Double(batchSize) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> PendingReferralClaim {
            return PendingReferralClaim(
                code: code,
                name: name,
                sequence: sequence,
                limit: limit,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending referral claim in status new.
    static func newPendingReferralClaim(_ code: String, name: String) -> PendingReferralClaim {
        return PendingReferralClaim(
            code: code,
            name: name,
            sequence: 0,
            limit: 0,
            batchSize: 0,
            status: PendingReferralClaimStatus.new
        )
    }
}
