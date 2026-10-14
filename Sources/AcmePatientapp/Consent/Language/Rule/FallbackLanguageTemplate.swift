import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback language template is in its life cycle.
    enum FallbackLanguageTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback language template. Its code is unique within a tenant.
    final class FallbackLanguageTemplate {
        var code: String
        var title: String
        var maximum: Double
        var archived: Bool
        var reviewer: String
        var active: Bool
        var updatedAt: Int
        var status: FallbackLanguageTemplateStatus

        init(code: String, title: String, maximum: Double, archived: Bool, reviewer: String, active: Bool, updatedAt: Int, status: FallbackLanguageTemplateStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.archived = archived
            self.reviewer = reviewer
            self.active = active
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: FallbackLanguageTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == FallbackLanguageTemplateStatus.resolved || next == FallbackLanguageTemplateStatus.reopened
            case .resolved:
                return next == FallbackLanguageTemplateStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: FallbackLanguageTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback language template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback language template") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((maximum - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackLanguageTemplate {
            return FallbackLanguageTemplate(
                code: code,
                title: title,
                maximum: maximum,
                archived: archived,
                reviewer: reviewer,
                active: active,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback language template in status open.
    static func newFallbackLanguageTemplate(_ code: String, title: String) -> FallbackLanguageTemplate {
        return FallbackLanguageTemplate(
            code: code,
            title: title,
            maximum: 0.0,
            archived: false,
            reviewer: "",
            active: false,
            updatedAt: 0,
            status: FallbackLanguageTemplateStatus.`open`
        )
    }
}
