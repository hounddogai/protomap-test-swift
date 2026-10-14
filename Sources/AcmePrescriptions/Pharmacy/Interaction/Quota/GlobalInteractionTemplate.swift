import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global interaction template is in its life cycle.
    enum GlobalInteractionTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One global interaction template, with what the planners need to act on it.
    final class GlobalInteractionTemplate {
        var code: String
        var title: String
        var createdAt: Int
        var visitMinutes: Int
        var attempts: Int
        var tags: [String]
        var status: GlobalInteractionTemplateStatus

        init(code: String, title: String, createdAt: Int, visitMinutes: Int, attempts: Int, tags: [String], status: GlobalInteractionTemplateStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.attempts = attempts
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalInteractionTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == GlobalInteractionTemplateStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GlobalInteractionTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global interaction template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global interaction template") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return (Double(visitMinutes) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> GlobalInteractionTemplate {
            return GlobalInteractionTemplate(
                code: code,
                title: title,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                attempts: attempts,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global interaction template in status idle.
    static func newGlobalInteractionTemplate(_ code: String, title: String) -> GlobalInteractionTemplate {
        return GlobalInteractionTemplate(
            code: code,
            title: title,
            createdAt: 0,
            visitMinutes: 0,
            attempts: 0,
            tags: [],
            status: GlobalInteractionTemplateStatus.idle
        )
    }
}
