import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy referral entry is in its life cycle.
    enum LegacyReferralEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One legacy referral entry, with what the planners need to act on it.
    final class LegacyReferralEntry {
        var code: String
        var title: String
        var name: String
        var margin: Double
        var floorValue: Double
        var status: LegacyReferralEntryStatus

        init(code: String, title: String, name: String, margin: Double, floorValue: Double, status: LegacyReferralEntryStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.margin = margin
            self.floorValue = floorValue
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

        func canMoveTo(_ next: LegacyReferralEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyReferralEntryStatus.queued || next == LegacyReferralEntryStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LegacyReferralEntryStatus.done
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

        func moveTo(_ next: LegacyReferralEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy referral entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy referral entry") \(code)"
        }

        func netVolume() -> Double {
            return ((floorValue + margin) * 100).rounded() / 100
        }

        func copyValue() -> LegacyReferralEntry {
            return LegacyReferralEntry(
                code: code,
                title: title,
                name: name,
                margin: margin,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy referral entry in status new.
    static func newLegacyReferralEntry(_ code: String, title: String) -> LegacyReferralEntry {
        return LegacyReferralEntry(
            code: code,
            title: title,
            name: "",
            margin: 0.0,
            floorValue: 0.0,
            status: LegacyReferralEntryStatus.new
        )
    }
}
