import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory variance is in its life cycle.
    enum InventoryVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A inventory variance as the inventory team keeps it.
    final class InventoryVariance {
        var code: String
        var title: String
        var expiresAt: Int
        var active: Bool
        var ownerID: String
        var refills: Int
        var ward: String
        var payer: String
        var notes: String
        var archived: Bool
        var status: InventoryVarianceStatus

        init(code: String, title: String, expiresAt: Int, active: Bool, ownerID: String, refills: Int, ward: String, payer: String, notes: String, archived: Bool, status: InventoryVarianceStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.active = active
            self.ownerID = ownerID
            self.refills = refills
            self.ward = ward
            self.payer = payer
            self.notes = notes
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryVarianceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == InventoryVarianceStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("inventory variance") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(expiresAt) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> InventoryVariance {
            return InventoryVariance(
                code: code,
                title: title,
                expiresAt: expiresAt,
                active: active,
                ownerID: ownerID,
                refills: refills,
                ward: ward,
                payer: payer,
                notes: notes,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a inventory variance in status created.
    static func newInventoryVariance(_ code: String, title: String) -> InventoryVariance {
        return InventoryVariance(
            code: code,
            title: title,
            expiresAt: 0,
            active: false,
            ownerID: "",
            refills: 0,
            ward: "",
            payer: "",
            notes: "",
            archived: false,
            status: InventoryVarianceStatus.created
        )
    }
}
