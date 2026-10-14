import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral manifest is in its life cycle.
    enum ReferralManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a referral manifest and its current status.
    final class ReferralManifest {
        var code: String
        var name: String
        var capacity: Int
        var payer: String
        var summary: String
        var status: ReferralManifestStatus

        init(code: String, name: String, capacity: Int, payer: String, summary: String, status: ReferralManifestStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.payer = payer
            self.summary = summary
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

        func canMoveTo(_ next: ReferralManifestStatus) -> Bool {
            switch status {
            case .new:
                return next == ReferralManifestStatus.failed
            case .queued:
                return next == ReferralManifestStatus.done
            case .running:
                return next == ReferralManifestStatus.done || next == ReferralManifestStatus.failed
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

        func moveTo(_ next: ReferralManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("referral manifest") \(code)"
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> ReferralManifest {
            return ReferralManifest(
                code: code,
                name: name,
                capacity: capacity,
                payer: payer,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral manifest in status new.
    static func newReferralManifest(_ code: String, name: String) -> ReferralManifest {
        return ReferralManifest(
            code: code,
            name: name,
            capacity: 0,
            payer: "",
            summary: "",
            status: ReferralManifestStatus.new
        )
    }
}
