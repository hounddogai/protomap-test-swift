import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial milestone is in its life cycle.
    enum DenialMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One denial milestone, with what the planners need to act on it.
    final class DenialMilestone {
        var code: String
        var name: String
        var attributes: [String: String]
        var updatedAt: Int
        var capacity: Int
        var discount: Double
        var tags: [String]
        var contactEmail: String
        var notes: String
        var quantity: Int
        var locale: String
        var status: DenialMilestoneStatus

        init(code: String, name: String, attributes: [String: String], updatedAt: Int, capacity: Int, discount: Double, tags: [String], contactEmail: String, notes: String, quantity: Int, locale: String, status: DenialMilestoneStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.discount = discount
            self.tags = tags
            self.contactEmail = contactEmail
            self.notes = notes
            self.quantity = quantity
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DenialMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                return next == DenialMilestoneStatus.pending
            case .pending:
                return next == DenialMilestoneStatus.suspended || next == DenialMilestoneStatus.closed
            case .active:
                return next == DenialMilestoneStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: DenialMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("denial milestone") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedExposure() -> Double {
            return (discount * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> DenialMilestone {
            return DenialMilestone(
                code: code,
                name: name,
                attributes: attributes,
                updatedAt: updatedAt,
                capacity: capacity,
                discount: discount,
                tags: tags,
                contactEmail: contactEmail,
                notes: notes,
                quantity: quantity,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a denial milestone in status draft.
    static func newDenialMilestone(_ code: String, name: String) -> DenialMilestone {
        return DenialMilestone(
            code: code,
            name: name,
            attributes: [:],
            updatedAt: 0,
            capacity: 0,
            discount: 0.0,
            tags: [],
            contactEmail: "",
            notes: "",
            quantity: 0,
            locale: "",
            status: DenialMilestoneStatus.draft
        )
    }
}
