import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback referral entry is in its life cycle.
    enum FallbackReferralEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One fallback referral entry, with what the planners need to act on it.
    final class FallbackReferralEntry {
        var code: String
        var title: String
        var ward: String
        var sequence: Int
        var graceDays: Int
        var floorValue: Double
        var phone: String
        var region: String
        var status: FallbackReferralEntryStatus

        init(code: String, title: String, ward: String, sequence: Int, graceDays: Int, floorValue: Double, phone: String, region: String, status: FallbackReferralEntryStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.sequence = sequence
            self.graceDays = graceDays
            self.floorValue = floorValue
            self.phone = phone
            self.region = region
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

        func canMoveTo(_ next: FallbackReferralEntryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FallbackReferralEntryStatus.draining || next == FallbackReferralEntryStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: FallbackReferralEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback referral entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback referral entry") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(graceDays) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> FallbackReferralEntry {
            return FallbackReferralEntry(
                code: code,
                title: title,
                ward: ward,
                sequence: sequence,
                graceDays: graceDays,
                floorValue: floorValue,
                phone: phone,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback referral entry in status idle.
    static func newFallbackReferralEntry(_ code: String, title: String) -> FallbackReferralEntry {
        return FallbackReferralEntry(
            code: code,
            title: title,
            ward: "",
            sequence: 0,
            graceDays: 0,
            floorValue: 0.0,
            phone: "",
            region: "",
            status: FallbackReferralEntryStatus.idle
        )
    }
}
