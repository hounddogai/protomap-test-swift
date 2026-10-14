import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory quota is in its life cycle.
    enum InventoryQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One inventory quota, with what the planners need to act on it.
    final class InventoryQuota {
        var code: String
        var name: String
        var floorValue: Double
        var ownerID: String
        var quantity: Int
        var durationMinutes: Int
        var clinicianID: String
        var attempts: Int
        var title: String
        var segment: String
        var status: InventoryQuotaStatus

        init(code: String, name: String, floorValue: Double, ownerID: String, quantity: Int, durationMinutes: Int, clinicianID: String, attempts: Int, title: String, segment: String, status: InventoryQuotaStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.ownerID = ownerID
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.clinicianID = clinicianID
            self.attempts = attempts
            self.title = title
            self.segment = segment
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

        func canMoveTo(_ next: InventoryQuotaStatus) -> Bool {
            switch status {
            case .new:
                return next == InventoryQuotaStatus.queued
            case .queued:
                return next == InventoryQuotaStatus.failed
            case .running:
                return next == InventoryQuotaStatus.done || next == InventoryQuotaStatus.failed
            case .done:
                return next == InventoryQuotaStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return ((Double(attempts) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryQuota {
            return InventoryQuota(
                code: code,
                name: name,
                floorValue: floorValue,
                ownerID: ownerID,
                quantity: quantity,
                durationMinutes: durationMinutes,
                clinicianID: clinicianID,
                attempts: attempts,
                title: title,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a inventory quota in status new.
    static func newInventoryQuota(_ code: String, name: String) -> InventoryQuota {
        return InventoryQuota(
            code: code,
            name: name,
            floorValue: 0.0,
            ownerID: "",
            quantity: 0,
            durationMinutes: 0,
            clinicianID: "",
            attempts: 0,
            title: "",
            segment: "",
            status: InventoryQuotaStatus.new
        )
    }
}
