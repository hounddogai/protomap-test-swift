import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict language assignment is in its life cycle.
    enum StrictLanguageAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict language assignment. Its code is unique within a tenant.
    final class StrictLanguageAssignment {
        var code: String
        var title: String
        var locale: String
        var category: String
        var retries: Int
        var visitMinutes: Int
        var description: String
        var rate: Double
        var durationMinutes: Int
        var status: StrictLanguageAssignmentStatus

        init(code: String, title: String, locale: String, category: String, retries: Int, visitMinutes: Int, description: String, rate: Double, durationMinutes: Int, status: StrictLanguageAssignmentStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.category = category
            self.retries = retries
            self.visitMinutes = visitMinutes
            self.description = description
            self.rate = rate
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: StrictLanguageAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StrictLanguageAssignmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictLanguageAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict language assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict language assignment") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(durationMinutes) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StrictLanguageAssignment {
            return StrictLanguageAssignment(
                code: code,
                title: title,
                locale: locale,
                category: category,
                retries: retries,
                visitMinutes: visitMinutes,
                description: description,
                rate: rate,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict language assignment in status draft.
    static func newStrictLanguageAssignment(_ code: String, title: String) -> StrictLanguageAssignment {
        return StrictLanguageAssignment(
            code: code,
            title: title,
            locale: "",
            category: "",
            retries: 0,
            visitMinutes: 0,
            description: "",
            rate: 0.0,
            durationMinutes: 0,
            status: StrictLanguageAssignmentStatus.draft
        )
    }
}
