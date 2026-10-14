import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped referral snapshot is in its life cycle.
    enum CappedReferralSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a capped referral snapshot and its current status.
    final class CappedReferralSnapshot {
        var code: String
        var name: String
        var graceDays: Int
        var locale: String
        var facility: String
        var status: CappedReferralSnapshotStatus

        init(code: String, name: String, graceDays: Int, locale: String, facility: String, status: CappedReferralSnapshotStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.locale = locale
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedReferralSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: CappedReferralSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped referral snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> CappedReferralSnapshot {
            return CappedReferralSnapshot(
                code: code,
                name: name,
                graceDays: graceDays,
                locale: locale,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a capped referral snapshot in status proposed.
    static func newCappedReferralSnapshot(_ code: String, name: String) -> CappedReferralSnapshot {
        return CappedReferralSnapshot(
            code: code,
            name: name,
            graceDays: 0,
            locale: "",
            facility: "",
            status: CappedReferralSnapshotStatus.proposed
        )
    }
}
