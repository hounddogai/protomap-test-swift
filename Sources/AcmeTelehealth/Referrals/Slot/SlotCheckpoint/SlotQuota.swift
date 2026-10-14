import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot quota is in its life cycle.
    enum SlotQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One slot quota, with what the planners need to act on it.
    final class SlotQuota {
        var code: String
        var title: String
        var category: String
        var encounterID: String
        var amount: Double
        var discount: Double
        var allergy: String
        var contactEmail: String
        var limit: Int
        var status: SlotQuotaStatus

        init(code: String, title: String, category: String, encounterID: String, amount: Double, discount: Double, allergy: String, contactEmail: String, limit: Int, status: SlotQuotaStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.encounterID = encounterID
            self.amount = amount
            self.discount = discount
            self.allergy = allergy
            self.contactEmail = contactEmail
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotQuotaStatus) -> Bool {
            switch status {
            case .idle:
                return next == SlotQuotaStatus.ready
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SlotQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("slot quota") \(code)"
        }

        func projectedValue() -> Double {
            return (amount * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> SlotQuota {
            return SlotQuota(
                code: code,
                title: title,
                category: category,
                encounterID: encounterID,
                amount: amount,
                discount: discount,
                allergy: allergy,
                contactEmail: contactEmail,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a slot quota in status idle.
    static func newSlotQuota(_ code: String, title: String) -> SlotQuota {
        return SlotQuota(
            code: code,
            title: title,
            category: "",
            encounterID: "",
            amount: 0.0,
            discount: 0.0,
            allergy: "",
            contactEmail: "",
            limit: 0,
            status: SlotQuotaStatus.idle
        )
    }
}
