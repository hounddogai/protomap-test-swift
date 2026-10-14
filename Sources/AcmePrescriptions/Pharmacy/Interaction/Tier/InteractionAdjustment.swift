import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction adjustment is in its life cycle.
    enum InteractionAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a interaction adjustment and its current status.
    final class InteractionAdjustment {
        var code: String
        var name: String
        var segment: String
        var tags: [String]
        var notes: String
        var amount: Double
        var status: InteractionAdjustmentStatus

        init(code: String, name: String, segment: String, tags: [String], notes: String, amount: Double, status: InteractionAdjustmentStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.tags = tags
            self.notes = notes
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InteractionAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == InteractionAdjustmentStatus.reopened
            case .resolved:
                return next == InteractionAdjustmentStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: InteractionAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> InteractionAdjustment {
            return InteractionAdjustment(
                code: code,
                name: name,
                segment: segment,
                tags: tags,
                notes: notes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a interaction adjustment in status open.
    static func newInteractionAdjustment(_ code: String, name: String) -> InteractionAdjustment {
        return InteractionAdjustment(
            code: code,
            name: name,
            segment: "",
            tags: [],
            notes: "",
            amount: 0.0,
            status: InteractionAdjustmentStatus.`open`
        )
    }
}
