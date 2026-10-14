import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff notice is in its life cycle.
    enum HandoffNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One handoff notice, with what the planners need to act on it.
    final class HandoffNotice {
        var code: String
        var title: String
        var locale: String
        var tags: [String]
        var retries: Int
        var quantity: Int
        var status: HandoffNoticeStatus

        init(code: String, title: String, locale: String, tags: [String], retries: Int, quantity: Int, status: HandoffNoticeStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.tags = tags
            self.retries = retries
            self.quantity = quantity
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

        func canMoveTo(_ next: HandoffNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
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

        func moveTo(_ next: HandoffNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return ((Double(retries) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffNotice {
            return HandoffNotice(
                code: code,
                title: title,
                locale: locale,
                tags: tags,
                retries: retries,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a handoff notice in status open.
    static func newHandoffNotice(_ code: String, title: String) -> HandoffNotice {
        return HandoffNotice(
            code: code,
            title: title,
            locale: "",
            tags: [],
            retries: 0,
            quantity: 0,
            status: HandoffNoticeStatus.`open`
        )
    }
}
