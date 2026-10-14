import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy consent form audit is in its life cycle.
    enum LegacyConsentFormAuditStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a legacy consent form audit and its current status.
    final class LegacyConsentFormAudit {
        var code: String
        var title: String
        var version: Int
        var name: String
        var attributes: [String: String]
        var margin: Double
        var quantity: Int
        var archived: Bool
        var createdAt: Int
        var status: LegacyConsentFormAuditStatus

        init(code: String, title: String, version: Int, name: String, attributes: [String: String], margin: Double, quantity: Int, archived: Bool, createdAt: Int, status: LegacyConsentFormAuditStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.name = name
            self.attributes = attributes
            self.margin = margin
            self.quantity = quantity
            self.archived = archived
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyConsentFormAuditStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LegacyConsentFormAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy consent form audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
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

        func adjustedTotal() -> Double {
            return ((Double(quantity) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyConsentFormAudit {
            return LegacyConsentFormAudit(
                code: code,
                title: title,
                version: version,
                name: name,
                attributes: attributes,
                margin: margin,
                quantity: quantity,
                archived: archived,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy consent form audit in status planned.
    static func newLegacyConsentFormAudit(_ code: String, title: String) -> LegacyConsentFormAudit {
        return LegacyConsentFormAudit(
            code: code,
            title: title,
            version: 0,
            name: "",
            attributes: [:],
            margin: 0.0,
            quantity: 0,
            archived: false,
            createdAt: 0,
            status: LegacyConsentFormAuditStatus.planned
        )
    }
}
