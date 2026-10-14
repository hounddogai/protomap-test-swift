import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction segment is in its life cycle.
    enum InteractionSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A interaction segment. Its code is unique within a tenant.
    final class InteractionSegment {
        var code: String
        var label: String
        var cost: Double
        var description: String
        var graceDays: Int
        var category: String
        var quantity: Int
        var refills: Int
        var tags: [String]
        var status: InteractionSegmentStatus

        init(code: String, label: String, cost: Double, description: String, graceDays: Int, category: String, quantity: Int, refills: Int, tags: [String], status: InteractionSegmentStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.description = description
            self.graceDays = graceDays
            self.category = category
            self.quantity = quantity
            self.refills = refills
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

        func canMoveTo(_ next: InteractionSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == InteractionSegmentStatus.approved || next == InteractionSegmentStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == InteractionSegmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("interaction segment") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return ((Double(quantity) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionSegment {
            return InteractionSegment(
                code: code,
                label: label,
                cost: cost,
                description: description,
                graceDays: graceDays,
                category: category,
                quantity: quantity,
                refills: refills,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a interaction segment in status proposed.
    static func newInteractionSegment(_ code: String, label: String) -> InteractionSegment {
        return InteractionSegment(
            code: code,
            label: label,
            cost: 0.0,
            description: "",
            graceDays: 0,
            category: "",
            quantity: 0,
            refills: 0,
            tags: [],
            status: InteractionSegmentStatus.proposed
        )
    }
}
