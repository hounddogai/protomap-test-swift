import AcmePlatform
import Foundation

extension Consent {
    /// Where a language plan is in its life cycle.
    enum LanguagePlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A language plan as the language team keeps it.
    final class LanguagePlan {
        var code: String
        var name: String
        var graceDays: Int
        var channel: String
        var contactEmail: String
        var procedureCode: String
        var encounterID: String
        var sequence: Int
        var category: String
        var locale: String
        var priority: Int
        var status: LanguagePlanStatus

        init(code: String, name: String, graceDays: Int, channel: String, contactEmail: String, procedureCode: String, encounterID: String, sequence: Int, category: String, locale: String, priority: Int, status: LanguagePlanStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.channel = channel
            self.contactEmail = contactEmail
            self.procedureCode = procedureCode
            self.encounterID = encounterID
            self.sequence = sequence
            self.category = category
            self.locale = locale
            self.priority = priority
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

        func canMoveTo(_ next: LanguagePlanStatus) -> Bool {
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
                return next == LanguagePlanStatus.inProgress || next == LanguagePlanStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LanguagePlanStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguagePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netVolume() -> Double {
            return ((Double(sequence) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LanguagePlan {
            return LanguagePlan(
                code: code,
                name: name,
                graceDays: graceDays,
                channel: channel,
                contactEmail: contactEmail,
                procedureCode: procedureCode,
                encounterID: encounterID,
                sequence: sequence,
                category: category,
                locale: locale,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a language plan in status planned.
    static func newLanguagePlan(_ code: String, name: String) -> LanguagePlan {
        return LanguagePlan(
            code: code,
            name: name,
            graceDays: 0,
            channel: "",
            contactEmail: "",
            procedureCode: "",
            encounterID: "",
            sequence: 0,
            category: "",
            locale: "",
            priority: 0,
            status: LanguagePlanStatus.planned
        )
    }
}
