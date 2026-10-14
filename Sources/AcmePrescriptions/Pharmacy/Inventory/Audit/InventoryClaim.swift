import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory claim is in its life cycle.
    enum InventoryClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A inventory claim as the inventory team keeps it.
    final class InventoryClaim {
        var code: String
        var name: String
        var notes: String
        var ward: String
        var createdAt: Int
        var ceiling: Double
        var rate: Double
        var description: String
        var status: InventoryClaimStatus

        init(code: String, name: String, notes: String, ward: String, createdAt: Int, ceiling: Double, rate: Double, description: String, status: InventoryClaimStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.ward = ward
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.rate = rate
            self.description = description
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

        func canMoveTo(_ next: InventoryClaimStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == InventoryClaimStatus.running
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == InventoryClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return ((Double(createdAt) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> InventoryClaim {
            return InventoryClaim(
                code: code,
                name: name,
                notes: notes,
                ward: ward,
                createdAt: createdAt,
                ceiling: ceiling,
                rate: rate,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a inventory claim in status new.
    static func newInventoryClaim(_ code: String, name: String) -> InventoryClaim {
        return InventoryClaim(
            code: code,
            name: name,
            notes: "",
            ward: "",
            createdAt: 0,
            ceiling: 0.0,
            rate: 0.0,
            description: "",
            status: InventoryClaimStatus.new
        )
    }
}
