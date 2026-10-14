import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered transfer record is in its life cycle.
    enum TieredTransferRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered transfer record as the transfer team keeps it.
    final class TieredTransferRecord {
        var code: String
        var title: String
        var phone: String
        var tags: [String]
        var windowDays: Int
        var discount: Double
        var status: TieredTransferRecordStatus

        init(code: String, title: String, phone: String, tags: [String], windowDays: Int, discount: Double, status: TieredTransferRecordStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.tags = tags
            self.windowDays = windowDays
            self.discount = discount
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

        func canMoveTo(_ next: TieredTransferRecordStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredTransferRecordStatus.rejected
            case .approved:
                return next == TieredTransferRecordStatus.rejected || next == TieredTransferRecordStatus.withdrawn
            case .rejected:
                return next == TieredTransferRecordStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredTransferRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered transfer record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((Double(windowDays) + discount) * 100).rounded() / 100
        }

        func copyValue() -> TieredTransferRecord {
            return TieredTransferRecord(
                code: code,
                title: title,
                phone: phone,
                tags: tags,
                windowDays: windowDays,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered transfer record in status proposed.
    static func newTieredTransferRecord(_ code: String, title: String) -> TieredTransferRecord {
        return TieredTransferRecord(
            code: code,
            title: title,
            phone: "",
            tags: [],
            windowDays: 0,
            discount: 0.0,
            status: TieredTransferRecordStatus.proposed
        )
    }
}
