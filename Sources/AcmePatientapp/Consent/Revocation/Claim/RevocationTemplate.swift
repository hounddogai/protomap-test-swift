import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation template is in its life cycle.
    enum RevocationTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A revocation template. Its code is unique within a tenant.
    final class RevocationTemplate {
        var code: String
        var label: String
        var procedureCode: String
        var country: String
        var dosageMg: Double
        var attributes: [String: String]
        var startsAt: Int
        var margin: Double
        var category: String
        var durationMinutes: Int
        var capacity: Int
        var status: RevocationTemplateStatus

        init(code: String, label: String, procedureCode: String, country: String, dosageMg: Double, attributes: [String: String], startsAt: Int, margin: Double, category: String, durationMinutes: Int, capacity: Int, status: RevocationTemplateStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.country = country
            self.dosageMg = dosageMg
            self.attributes = attributes
            self.startsAt = startsAt
            self.margin = margin
            self.category = category
            self.durationMinutes = durationMinutes
            self.capacity = capacity
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

        func canMoveTo(_ next: RevocationTemplateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RevocationTemplateStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: RevocationTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func netExposure() -> Double {
            return (dosageMg * margin * 100).rounded() / 100
        }

        func copyValue() -> RevocationTemplate {
            return RevocationTemplate(
                code: code,
                label: label,
                procedureCode: procedureCode,
                country: country,
                dosageMg: dosageMg,
                attributes: attributes,
                startsAt: startsAt,
                margin: margin,
                category: category,
                durationMinutes: durationMinutes,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a revocation template in status planned.
    static func newRevocationTemplate(_ code: String, label: String) -> RevocationTemplate {
        return RevocationTemplate(
            code: code,
            label: label,
            procedureCode: "",
            country: "",
            dosageMg: 0.0,
            attributes: [:],
            startsAt: 0,
            margin: 0.0,
            category: "",
            durationMinutes: 0,
            capacity: 0,
            status: RevocationTemplateStatus.planned
        )
    }
}
