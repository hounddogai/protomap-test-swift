import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility snapshot is in its life cycle.
    enum EligibilitySnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A eligibility snapshot as the eligibility team keeps it.
    final class EligibilitySnapshot {
        var code: String
        var label: String
        var attributes: [String: String]
        var tags: [String]
        var name: String
        var quantity: Int
        var status: EligibilitySnapshotStatus

        init(code: String, label: String, attributes: [String: String], tags: [String], name: String, quantity: Int, status: EligibilitySnapshotStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.tags = tags
            self.name = name
            self.quantity = quantity
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

        func canMoveTo(_ next: EligibilitySnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == EligibilitySnapshotStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == EligibilitySnapshotStatus.reopened || next == EligibilitySnapshotStatus.archived
            case .reopened:
                return next == EligibilitySnapshotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilitySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("eligibility snapshot") \(code)"
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

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> EligibilitySnapshot {
            return EligibilitySnapshot(
                code: code,
                label: label,
                attributes: attributes,
                tags: tags,
                name: name,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a eligibility snapshot in status open.
    static func newEligibilitySnapshot(_ code: String, label: String) -> EligibilitySnapshot {
        return EligibilitySnapshot(
            code: code,
            label: label,
            attributes: [:],
            tags: [],
            name: "",
            quantity: 0,
            status: EligibilitySnapshotStatus.`open`
        )
    }
}
