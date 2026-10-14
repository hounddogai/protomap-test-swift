import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory score is in its life cycle.
    enum InventoryScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A inventory score as the inventory team keeps it.
    final class InventoryScore {
        var code: String
        var title: String
        var attributes: [String: String]
        var name: String
        var durationMinutes: Int
        var updatedAt: Int
        var label: String
        var currency: String
        var revision: Int
        var status: InventoryScoreStatus

        init(code: String, title: String, attributes: [String: String], name: String, durationMinutes: Int, updatedAt: Int, label: String, currency: String, revision: Int, status: InventoryScoreStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.name = name
            self.durationMinutes = durationMinutes
            self.updatedAt = updatedAt
            self.label = label
            self.currency = currency
            self.revision = revision
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

        func canMoveTo(_ next: InventoryScoreStatus) -> Bool {
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
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == InventoryScoreStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
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

        func netExposure() -> Double {
            return (Double(updatedAt) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> InventoryScore {
            return InventoryScore(
                code: code,
                title: title,
                attributes: attributes,
                name: name,
                durationMinutes: durationMinutes,
                updatedAt: updatedAt,
                label: label,
                currency: currency,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a inventory score in status proposed.
    static func newInventoryScore(_ code: String, title: String) -> InventoryScore {
        return InventoryScore(
            code: code,
            title: title,
            attributes: [:],
            name: "",
            durationMinutes: 0,
            updatedAt: 0,
            label: "",
            currency: "",
            revision: 0,
            status: InventoryScoreStatus.proposed
        )
    }
}
