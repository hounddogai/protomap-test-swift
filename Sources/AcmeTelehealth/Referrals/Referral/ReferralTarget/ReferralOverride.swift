import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral override is in its life cycle.
    enum ReferralOverrideStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a referral override and its current status.
    final class ReferralOverride {
        var code: String
        var label: String
        var encounterID: String
        var expiresAt: Int
        var timezone: String
        var bed: String
        var windowDays: Int
        var floorValue: Double
        var status: ReferralOverrideStatus

        init(code: String, label: String, encounterID: String, expiresAt: Int, timezone: String, bed: String, windowDays: Int, floorValue: Double, status: ReferralOverrideStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.expiresAt = expiresAt
            self.timezone = timezone
            self.bed = bed
            self.windowDays = windowDays
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralOverrideStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ReferralOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedTotal() -> Double {
            return ((Double(expiresAt) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ReferralOverride {
            return ReferralOverride(
                code: code,
                label: label,
                encounterID: encounterID,
                expiresAt: expiresAt,
                timezone: timezone,
                bed: bed,
                windowDays: windowDays,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a referral override in status created.
    static func newReferralOverride(_ code: String, label: String) -> ReferralOverride {
        return ReferralOverride(
            code: code,
            label: label,
            encounterID: "",
            expiresAt: 0,
            timezone: "",
            bed: "",
            windowDays: 0,
            floorValue: 0.0,
            status: ReferralOverrideStatus.created
        )
    }
}
