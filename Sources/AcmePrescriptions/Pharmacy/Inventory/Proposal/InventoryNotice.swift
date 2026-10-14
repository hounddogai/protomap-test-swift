import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory notice is in its life cycle.
    enum InventoryNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a inventory notice and its current status.
    final class InventoryNotice {
        var code: String
        var title: String
        var updatedAt: Int
        var label: String
        var approved: Bool
        var version: Int
        var currency: String
        var clinicianID: String
        var status: InventoryNoticeStatus

        init(code: String, title: String, updatedAt: Int, label: String, approved: Bool, version: Int, currency: String, clinicianID: String, status: InventoryNoticeStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.label = label
            self.approved = approved
            self.version = version
            self.currency = currency
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: InventoryNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == InventoryNoticeStatus.granted || next == InventoryNoticeStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: InventoryNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return ((Double(updatedAt) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryNotice {
            return InventoryNotice(
                code: code,
                title: title,
                updatedAt: updatedAt,
                label: label,
                approved: approved,
                version: version,
                currency: currency,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a inventory notice in status requested.
    static func newInventoryNotice(_ code: String, title: String) -> InventoryNotice {
        return InventoryNotice(
            code: code,
            title: title,
            updatedAt: 0,
            label: "",
            approved: false,
            version: 0,
            currency: "",
            clinicianID: "",
            status: InventoryNoticeStatus.requested
        )
    }
}
