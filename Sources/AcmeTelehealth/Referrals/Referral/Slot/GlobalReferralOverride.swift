import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global referral override is in its life cycle.
    enum GlobalReferralOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a global referral override and its current status.
    final class GlobalReferralOverride {
        var code: String
        var title: String
        var weight: Double
        var channel: String
        var notes: String
        var expiresAt: Int
        var summary: String
        var createdAt: Int
        var status: GlobalReferralOverrideStatus

        init(code: String, title: String, weight: Double, channel: String, notes: String, expiresAt: Int, summary: String, createdAt: Int, status: GlobalReferralOverrideStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.channel = channel
            self.notes = notes
            self.expiresAt = expiresAt
            self.summary = summary
            self.createdAt = createdAt
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

        func canMoveTo(_ next: GlobalReferralOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalReferralOverrideStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: GlobalReferralOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global referral override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netLoad() -> Double {
            return ((Double(createdAt) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalReferralOverride {
            return GlobalReferralOverride(
                code: code,
                title: title,
                weight: weight,
                channel: channel,
                notes: notes,
                expiresAt: expiresAt,
                summary: summary,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global referral override in status new.
    static func newGlobalReferralOverride(_ code: String, title: String) -> GlobalReferralOverride {
        return GlobalReferralOverride(
            code: code,
            title: title,
            weight: 0.0,
            channel: "",
            notes: "",
            expiresAt: 0,
            summary: "",
            createdAt: 0,
            status: GlobalReferralOverrideStatus.new
        )
    }
}
