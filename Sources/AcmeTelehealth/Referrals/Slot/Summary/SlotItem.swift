import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot item is in its life cycle.
    enum SlotItemStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One slot item, with what the planners need to act on it.
    final class SlotItem {
        var code: String
        var label: String
        var title: String
        var ratio: Double
        var procedureCode: String
        var locale: String
        var summary: String
        var graceDays: Int
        var status: SlotItemStatus

        init(code: String, label: String, title: String, ratio: Double, procedureCode: String, locale: String, summary: String, graceDays: Int, status: SlotItemStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.locale = locale
            self.summary = summary
            self.graceDays = graceDays
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

        func canMoveTo(_ next: SlotItemStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == SlotItemStatus.revoked
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

        func moveTo(_ next: SlotItemStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot item \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(graceDays) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> SlotItem {
            return SlotItem(
                code: code,
                label: label,
                title: title,
                ratio: ratio,
                procedureCode: procedureCode,
                locale: locale,
                summary: summary,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a slot item in status requested.
    static func newSlotItem(_ code: String, label: String) -> SlotItem {
        return SlotItem(
            code: code,
            label: label,
            title: "",
            ratio: 0.0,
            procedureCode: "",
            locale: "",
            summary: "",
            graceDays: 0,
            status: SlotItemStatus.requested
        )
    }
}
