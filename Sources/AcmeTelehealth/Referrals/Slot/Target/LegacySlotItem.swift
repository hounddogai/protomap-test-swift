import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy slot item is in its life cycle.
    enum LegacySlotItemStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A legacy slot item as the slot team keeps it.
    final class LegacySlotItem {
        var code: String
        var title: String
        var name: String
        var visitMinutes: Int
        var visible: Bool
        var attributes: [String: String]
        var floorValue: Double
        var ratio: Double
        var cost: Double
        var status: LegacySlotItemStatus

        init(code: String, title: String, name: String, visitMinutes: Int, visible: Bool, attributes: [String: String], floorValue: Double, ratio: Double, cost: Double, status: LegacySlotItemStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.attributes = attributes
            self.floorValue = floorValue
            self.ratio = ratio
            self.cost = cost
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

        func canMoveTo(_ next: LegacySlotItemStatus) -> Bool {
            switch status {
            case .requested:
                return next == LegacySlotItemStatus.granted || next == LegacySlotItemStatus.expired
            case .granted:
                return next == LegacySlotItemStatus.revoked || next == LegacySlotItemStatus.expired
            case .revoked:
                return next == LegacySlotItemStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacySlotItemStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy slot item \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveExposure() -> Double {
            return (floorValue * cost * 100).rounded() / 100
        }

        func copyValue() -> LegacySlotItem {
            return LegacySlotItem(
                code: code,
                title: title,
                name: name,
                visitMinutes: visitMinutes,
                visible: visible,
                attributes: attributes,
                floorValue: floorValue,
                ratio: ratio,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy slot item in status requested.
    static func newLegacySlotItem(_ code: String, title: String) -> LegacySlotItem {
        return LegacySlotItem(
            code: code,
            title: title,
            name: "",
            visitMinutes: 0,
            visible: false,
            attributes: [:],
            floorValue: 0.0,
            ratio: 0.0,
            cost: 0.0,
            status: LegacySlotItemStatus.requested
        )
    }
}
