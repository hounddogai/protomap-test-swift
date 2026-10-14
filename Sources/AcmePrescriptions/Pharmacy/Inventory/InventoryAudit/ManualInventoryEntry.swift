import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual inventory entry is in its life cycle.
    enum ManualInventoryEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual inventory entry. Its code is unique within a tenant.
    final class ManualInventoryEntry {
        var code: String
        var name: String
        var acuity: Int
        var contactEmail: String
        var maximum: Double
        var currency: String
        var priority: Int
        var quantity: Int
        var retries: Int
        var status: ManualInventoryEntryStatus

        init(code: String, name: String, acuity: Int, contactEmail: String, maximum: Double, currency: String, priority: Int, quantity: Int, retries: Int, status: ManualInventoryEntryStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.contactEmail = contactEmail
            self.maximum = maximum
            self.currency = currency
            self.priority = priority
            self.quantity = quantity
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualInventoryEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == ManualInventoryEntryStatus.running || next == ManualInventoryEntryStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ManualInventoryEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual inventory entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedValue() -> Double {
            return ((Double(quantity) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ManualInventoryEntry {
            return ManualInventoryEntry(
                code: code,
                name: name,
                acuity: acuity,
                contactEmail: contactEmail,
                maximum: maximum,
                currency: currency,
                priority: priority,
                quantity: quantity,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual inventory entry in status new.
    static func newManualInventoryEntry(_ code: String, name: String) -> ManualInventoryEntry {
        return ManualInventoryEntry(
            code: code,
            name: name,
            acuity: 0,
            contactEmail: "",
            maximum: 0.0,
            currency: "",
            priority: 0,
            quantity: 0,
            retries: 0,
            status: ManualInventoryEntryStatus.new
        )
    }
}
