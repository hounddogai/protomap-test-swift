import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback cleaning template is in its life cycle.
    enum FallbackCleaningTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback cleaning template. Its code is unique within a tenant.
    final class FallbackCleaningTemplate {
        var code: String
        var name: String
        var unit: String
        var externalRef: String
        var country: String
        var attributes: [String: String]
        var createdAt: Int
        var timezone: String
        var payer: String
        var minimum: Double
        var title: String
        var status: FallbackCleaningTemplateStatus

        init(code: String, name: String, unit: String, externalRef: String, country: String, attributes: [String: String], createdAt: Int, timezone: String, payer: String, minimum: Double, title: String, status: FallbackCleaningTemplateStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.externalRef = externalRef
            self.country = country
            self.attributes = attributes
            self.createdAt = createdAt
            self.timezone = timezone
            self.payer = payer
            self.minimum = minimum
            self.title = title
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

        func canMoveTo(_ next: FallbackCleaningTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackCleaningTemplateStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
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
                return next == FallbackCleaningTemplateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCleaningTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback cleaning template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback cleaning template") \(code)"
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

        func netVolume() -> Double {
            return ((Double(createdAt) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCleaningTemplate {
            return FallbackCleaningTemplate(
                code: code,
                name: name,
                unit: unit,
                externalRef: externalRef,
                country: country,
                attributes: attributes,
                createdAt: createdAt,
                timezone: timezone,
                payer: payer,
                minimum: minimum,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a fallback cleaning template in status open.
    static func newFallbackCleaningTemplate(_ code: String, name: String) -> FallbackCleaningTemplate {
        return FallbackCleaningTemplate(
            code: code,
            name: name,
            unit: "",
            externalRef: "",
            country: "",
            attributes: [:],
            createdAt: 0,
            timezone: "",
            payer: "",
            minimum: 0.0,
            title: "",
            status: FallbackCleaningTemplateStatus.`open`
        )
    }
}
