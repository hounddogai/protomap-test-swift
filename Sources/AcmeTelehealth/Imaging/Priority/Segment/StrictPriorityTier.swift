import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict priority tier is in its life cycle.
    enum StrictPriorityTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a strict priority tier and its current status.
    final class StrictPriorityTier {
        var code: String
        var label: String
        var tags: [String]
        var notes: String
        var quantity: Int
        var amount: Double
        var contactEmail: String
        var name: String
        var summary: String
        var externalRef: String
        var status: StrictPriorityTierStatus

        init(code: String, label: String, tags: [String], notes: String, quantity: Int, amount: Double, contactEmail: String, name: String, summary: String, externalRef: String, status: StrictPriorityTierStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.notes = notes
            self.quantity = quantity
            self.amount = amount
            self.contactEmail = contactEmail
            self.name = name
            self.summary = summary
            self.externalRef = externalRef
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

        func canMoveTo(_ next: StrictPriorityTierStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == StrictPriorityTierStatus.archived
            case .reopened:
                return next == StrictPriorityTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictPriorityTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict priority tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return (amount * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> StrictPriorityTier {
            return StrictPriorityTier(
                code: code,
                label: label,
                tags: tags,
                notes: notes,
                quantity: quantity,
                amount: amount,
                contactEmail: contactEmail,
                name: name,
                summary: summary,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict priority tier in status open.
    static func newStrictPriorityTier(_ code: String, label: String) -> StrictPriorityTier {
        return StrictPriorityTier(
            code: code,
            label: label,
            tags: [],
            notes: "",
            quantity: 0,
            amount: 0.0,
            contactEmail: "",
            name: "",
            summary: "",
            externalRef: "",
            status: StrictPriorityTierStatus.`open`
        )
    }
}
