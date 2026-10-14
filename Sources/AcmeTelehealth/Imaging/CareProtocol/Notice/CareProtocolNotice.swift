import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol notice is in its life cycle.
    enum CareProtocolNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A care protocol notice. Its code is unique within a tenant.
    final class CareProtocolNotice {
        var code: String
        var title: String
        var quantity: Int
        var payer: String
        var region: String
        var ratio: Double
        var status: CareProtocolNoticeStatus

        init(code: String, title: String, quantity: Int, payer: String, region: String, ratio: Double, status: CareProtocolNoticeStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.payer = payer
            self.region = region
            self.ratio = ratio
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

        func canMoveTo(_ next: CareProtocolNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareProtocolNoticeStatus.revoked || next == CareProtocolNoticeStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CareProtocolNoticeStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedTotal() -> Double {
            return (ratio * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolNotice {
            return CareProtocolNotice(
                code: code,
                title: title,
                quantity: quantity,
                payer: payer,
                region: region,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a care protocol notice in status requested.
    static func newCareProtocolNotice(_ code: String, title: String) -> CareProtocolNotice {
        return CareProtocolNotice(
            code: code,
            title: title,
            quantity: 0,
            payer: "",
            region: "",
            ratio: 0.0,
            status: CareProtocolNoticeStatus.requested
        )
    }
}
