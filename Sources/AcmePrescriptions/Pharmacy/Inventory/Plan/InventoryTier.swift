import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory tier is in its life cycle.
    enum InventoryTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A inventory tier as the inventory team keeps it.
    final class InventoryTier {
        var code: String
        var label: String
        var archived: Bool
        var retries: Int
        var attributes: [String: String]
        var segment: String
        var visitMinutes: Int
        var margin: Double
        var tags: [String]
        var status: InventoryTierStatus

        init(code: String, label: String, archived: Bool, retries: Int, attributes: [String: String], segment: String, visitMinutes: Int, margin: Double, tags: [String], status: InventoryTierStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.retries = retries
            self.attributes = attributes
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.margin = margin
            self.tags = tags
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

        func canMoveTo(_ next: InventoryTierStatus) -> Bool {
            switch status {
            case .proposed:
                return next == InventoryTierStatus.rejected || next == InventoryTierStatus.withdrawn
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

        func moveTo(_ next: InventoryTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func weightedValue() -> Double {
            return (margin * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> InventoryTier {
            return InventoryTier(
                code: code,
                label: label,
                archived: archived,
                retries: retries,
                attributes: attributes,
                segment: segment,
                visitMinutes: visitMinutes,
                margin: margin,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a inventory tier in status proposed.
    static func newInventoryTier(_ code: String, label: String) -> InventoryTier {
        return InventoryTier(
            code: code,
            label: label,
            archived: false,
            retries: 0,
            attributes: [:],
            segment: "",
            visitMinutes: 0,
            margin: 0.0,
            tags: [],
            status: InventoryTierStatus.proposed
        )
    }
}
