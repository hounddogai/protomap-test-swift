import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool draft is in its life cycle.
    enum FloatPoolDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One float pool draft, with what the planners need to act on it.
    final class FloatPoolDraft {
        var code: String
        var name: String
        var discount: Double
        var margin: Double
        var category: String
        var status: FloatPoolDraftStatus

        init(code: String, name: String, discount: Double, margin: Double, category: String, status: FloatPoolDraftStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.margin = margin
            self.category = category
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

        func canMoveTo(_ next: FloatPoolDraftStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FloatPoolDraftStatus.archived
            case .inReview:
                return next == FloatPoolDraftStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FloatPoolDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveLoad() -> Double {
            return (discount * margin * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolDraft {
            return FloatPoolDraft(
                code: code,
                name: name,
                discount: discount,
                margin: margin,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a float pool draft in status open.
    static func newFloatPoolDraft(_ code: String, name: String) -> FloatPoolDraft {
        return FloatPoolDraft(
            code: code,
            name: name,
            discount: 0.0,
            margin: 0.0,
            category: "",
            status: FloatPoolDraftStatus.`open`
        )
    }
}
