import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure record is in its life cycle.
    enum DisclosureRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A disclosure record as the disclosure team keeps it.
    final class DisclosureRecord {
        var code: String
        var title: String
        var endsAt: Int
        var category: String
        var active: Bool
        var archived: Bool
        var attributes: [String: String]
        var status: DisclosureRecordStatus

        init(code: String, title: String, endsAt: Int, category: String, active: Bool, archived: Bool, attributes: [String: String], status: DisclosureRecordStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.category = category
            self.active = active
            self.archived = archived
            self.attributes = attributes
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

        func canMoveTo(_ next: DisclosureRecordStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DisclosureRecordStatus.reopened
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == DisclosureRecordStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
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
            return Double(endsAt)
        }

        func copyValue() -> DisclosureRecord {
            return DisclosureRecord(
                code: code,
                title: title,
                endsAt: endsAt,
                category: category,
                active: active,
                archived: archived,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a disclosure record in status open.
    static func newDisclosureRecord(_ code: String, title: String) -> DisclosureRecord {
        return DisclosureRecord(
            code: code,
            title: title,
            endsAt: 0,
            category: "",
            active: false,
            archived: false,
            attributes: [:],
            status: DisclosureRecordStatus.`open`
        )
    }
}
