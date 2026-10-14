import AcmePlatform
import Foundation

extension Consent {
    /// Where a language batch is in its life cycle.
    enum LanguageBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a language batch and its current status.
    final class LanguageBatch {
        var code: String
        var title: String
        var phone: String
        var category: String
        var contactEmail: String
        var maximum: Double
        var startsAt: Int
        var procedureCode: String
        var source: String
        var acuity: Int
        var amount: Double
        var status: LanguageBatchStatus

        init(code: String, title: String, phone: String, category: String, contactEmail: String, maximum: Double, startsAt: Int, procedureCode: String, source: String, acuity: Int, amount: Double, status: LanguageBatchStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.category = category
            self.contactEmail = contactEmail
            self.maximum = maximum
            self.startsAt = startsAt
            self.procedureCode = procedureCode
            self.source = source
            self.acuity = acuity
            self.amount = amount
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

        func canMoveTo(_ next: LanguageBatchStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LanguageBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("language batch") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(acuity) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageBatch {
            return LanguageBatch(
                code: code,
                title: title,
                phone: phone,
                category: category,
                contactEmail: contactEmail,
                maximum: maximum,
                startsAt: startsAt,
                procedureCode: procedureCode,
                source: source,
                acuity: acuity,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a language batch in status proposed.
    static func newLanguageBatch(_ code: String, title: String) -> LanguageBatch {
        return LanguageBatch(
            code: code,
            title: title,
            phone: "",
            category: "",
            contactEmail: "",
            maximum: 0.0,
            startsAt: 0,
            procedureCode: "",
            source: "",
            acuity: 0,
            amount: 0.0,
            status: LanguageBatchStatus.proposed
        )
    }
}
