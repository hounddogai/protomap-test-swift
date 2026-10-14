import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive shift notice is in its life cycle.
    enum AdaptiveShiftNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive shift notice as the shift team keeps it.
    final class AdaptiveShiftNotice {
        var code: String
        var title: String
        var ownerID: String
        var phone: String
        var pinned: Bool
        var name: String
        var amount: Double
        var status: AdaptiveShiftNoticeStatus

        init(code: String, title: String, ownerID: String, phone: String, pinned: Bool, name: String, amount: Double, status: AdaptiveShiftNoticeStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.phone = phone
            self.pinned = pinned
            self.name = name
            self.amount = amount
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

        func canMoveTo(_ next: AdaptiveShiftNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveShiftNoticeStatus.expired
            case .granted:
                return next == AdaptiveShiftNoticeStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AdaptiveShiftNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive shift notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> AdaptiveShiftNotice {
            return AdaptiveShiftNotice(
                code: code,
                title: title,
                ownerID: ownerID,
                phone: phone,
                pinned: pinned,
                name: name,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive shift notice in status requested.
    static func newAdaptiveShiftNotice(_ code: String, title: String) -> AdaptiveShiftNotice {
        return AdaptiveShiftNotice(
            code: code,
            title: title,
            ownerID: "",
            phone: "",
            pinned: false,
            name: "",
            amount: 0.0,
            status: AdaptiveShiftNoticeStatus.requested
        )
    }
}
