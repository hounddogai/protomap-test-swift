import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback priority slot is in its life cycle.
    enum FallbackPrioritySlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a fallback priority slot and its current status.
    final class FallbackPrioritySlot {
        var code: String
        var title: String
        var cost: Double
        var ownerID: String
        var source: String
        var amount: Double
        var revision: Int
        var currency: String
        var tags: [String]
        var status: FallbackPrioritySlotStatus

        init(code: String, title: String, cost: Double, ownerID: String, source: String, amount: Double, revision: Int, currency: String, tags: [String], status: FallbackPrioritySlotStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.ownerID = ownerID
            self.source = source
            self.amount = amount
            self.revision = revision
            self.currency = currency
            self.tags = tags
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

        func canMoveTo(_ next: FallbackPrioritySlotStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackPrioritySlotStatus.expired
            case .granted:
                return next == FallbackPrioritySlotStatus.expired
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

        func moveTo(_ next: FallbackPrioritySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback priority slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("fallback priority slot") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return (Double(revision) * amount * 100).rounded() / 100
        }

        func copyValue() -> FallbackPrioritySlot {
            return FallbackPrioritySlot(
                code: code,
                title: title,
                cost: cost,
                ownerID: ownerID,
                source: source,
                amount: amount,
                revision: revision,
                currency: currency,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a fallback priority slot in status requested.
    static func newFallbackPrioritySlot(_ code: String, title: String) -> FallbackPrioritySlot {
        return FallbackPrioritySlot(
            code: code,
            title: title,
            cost: 0.0,
            ownerID: "",
            source: "",
            amount: 0.0,
            revision: 0,
            currency: "",
            tags: [],
            status: FallbackPrioritySlotStatus.requested
        )
    }
}
