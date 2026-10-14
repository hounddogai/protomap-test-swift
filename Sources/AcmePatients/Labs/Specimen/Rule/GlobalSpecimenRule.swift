import AcmePlatform
import Foundation

extension Labs {
    /// Where a global specimen rule is in its life cycle.
    enum GlobalSpecimenRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global specimen rule as the specimen team keeps it.
    final class GlobalSpecimenRule {
        var code: String
        var title: String
        var allergy: String
        var contactEmail: String
        var acuity: Int
        var windowDays: Int
        var attempts: Int
        var status: GlobalSpecimenRuleStatus

        init(code: String, title: String, allergy: String, contactEmail: String, acuity: Int, windowDays: Int, attempts: Int, status: GlobalSpecimenRuleStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.contactEmail = contactEmail
            self.acuity = acuity
            self.windowDays = windowDays
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalSpecimenRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: GlobalSpecimenRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global specimen rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global specimen rule") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(acuity) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSpecimenRule {
            return GlobalSpecimenRule(
                code: code,
                title: title,
                allergy: allergy,
                contactEmail: contactEmail,
                acuity: acuity,
                windowDays: windowDays,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global specimen rule in status new.
    static func newGlobalSpecimenRule(_ code: String, title: String) -> GlobalSpecimenRule {
        return GlobalSpecimenRule(
            code: code,
            title: title,
            allergy: "",
            contactEmail: "",
            acuity: 0,
            windowDays: 0,
            attempts: 0,
            status: GlobalSpecimenRuleStatus.new
        )
    }
}
