import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot estimate is in its life cycle.
    enum SlotEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a slot estimate and its current status.
    final class SlotEstimate {
        var code: String
        var title: String
        var reviewer: String
        var phone: String
        var retries: Int
        var country: String
        var status: SlotEstimateStatus

        init(code: String, title: String, reviewer: String, phone: String, retries: Int, country: String, status: SlotEstimateStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.phone = phone
            self.retries = retries
            self.country = country
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

        func canMoveTo(_ next: SlotEstimateStatus) -> Bool {
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
                return next == SlotEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("slot estimate") \(code)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> SlotEstimate {
            return SlotEstimate(
                code: code,
                title: title,
                reviewer: reviewer,
                phone: phone,
                retries: retries,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a slot estimate in status requested.
    static func newSlotEstimate(_ code: String, title: String) -> SlotEstimate {
        return SlotEstimate(
            code: code,
            title: title,
            reviewer: "",
            phone: "",
            retries: 0,
            country: "",
            status: SlotEstimateStatus.requested
        )
    }
}
