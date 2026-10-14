import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network slot is in its life cycle.
    enum NetworkSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One network slot, with what the planners need to act on it.
    final class NetworkSlot {
        var code: String
        var label: String
        var clinicianID: String
        var margin: Double
        var quantity: Int
        var ownerID: String
        var reviewer: String
        var expiresAt: Int
        var limit: Int
        var description: String
        var status: NetworkSlotStatus

        init(code: String, label: String, clinicianID: String, margin: Double, quantity: Int, ownerID: String, reviewer: String, expiresAt: Int, limit: Int, description: String, status: NetworkSlotStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.margin = margin
            self.quantity = quantity
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.expiresAt = expiresAt
            self.limit = limit
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

        func canMoveTo(_ next: NetworkSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == NetworkSlotStatus.done
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == NetworkSlotStatus.done
            case .done:
                return next == NetworkSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("network slot") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(expiresAt) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> NetworkSlot {
            return NetworkSlot(
                code: code,
                label: label,
                clinicianID: clinicianID,
                margin: margin,
                quantity: quantity,
                ownerID: ownerID,
                reviewer: reviewer,
                expiresAt: expiresAt,
                limit: limit,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a network slot in status new.
    static func newNetworkSlot(_ code: String, label: String) -> NetworkSlot {
        return NetworkSlot(
            code: code,
            label: label,
            clinicianID: "",
            margin: 0.0,
            quantity: 0,
            ownerID: "",
            reviewer: "",
            expiresAt: 0,
            limit: 0,
            description: "",
            status: NetworkSlotStatus.new
        )
    }
}
