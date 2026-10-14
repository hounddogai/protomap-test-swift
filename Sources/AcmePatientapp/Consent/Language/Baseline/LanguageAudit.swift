import AcmePlatform
import Foundation

extension Consent {
    /// Where a language audit is in its life cycle.
    enum LanguageAuditStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A language audit as the language team keeps it.
    final class LanguageAudit {
        var code: String
        var name: String
        var unit: String
        var attributes: [String: String]
        var approved: Bool
        var ownerID: String
        var attempts: Int
        var graceDays: Int
        var procedureCode: String
        var amount: Double
        var currency: String
        var status: LanguageAuditStatus

        init(code: String, name: String, unit: String, attributes: [String: String], approved: Bool, ownerID: String, attempts: Int, graceDays: Int, procedureCode: String, amount: Double, currency: String, status: LanguageAuditStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.attributes = attributes
            self.approved = approved
            self.ownerID = ownerID
            self.attempts = attempts
            self.graceDays = graceDays
            self.procedureCode = procedureCode
            self.amount = amount
            self.currency = currency
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

        func canMoveTo(_ next: LanguageAuditStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LanguageAuditStatus.inProgress || next == LanguageAuditStatus.completed
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

        func moveTo(_ next: LanguageAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("language audit") \(code)"
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

        func adjustedVolume() -> Double {
            return (amount * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> LanguageAudit {
            return LanguageAudit(
                code: code,
                name: name,
                unit: unit,
                attributes: attributes,
                approved: approved,
                ownerID: ownerID,
                attempts: attempts,
                graceDays: graceDays,
                procedureCode: procedureCode,
                amount: amount,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a language audit in status planned.
    static func newLanguageAudit(_ code: String, name: String) -> LanguageAudit {
        return LanguageAudit(
            code: code,
            name: name,
            unit: "",
            attributes: [:],
            approved: false,
            ownerID: "",
            attempts: 0,
            graceDays: 0,
            procedureCode: "",
            amount: 0.0,
            currency: "",
            status: LanguageAuditStatus.planned
        )
    }
}
