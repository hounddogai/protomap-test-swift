import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff template is in its life cycle.
    enum HandoffTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A handoff template as the handoff team keeps it.
    final class HandoffTemplate {
        var code: String
        var name: String
        var reviewer: String
        var revision: Int
        var channel: String
        var status: HandoffTemplateStatus

        init(code: String, name: String, reviewer: String, revision: Int, channel: String, status: HandoffTemplateStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.revision = revision
            self.channel = channel
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

        func canMoveTo(_ next: HandoffTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: HandoffTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("handoff template") \(code)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> HandoffTemplate {
            return HandoffTemplate(
                code: code,
                name: name,
                reviewer: reviewer,
                revision: revision,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a handoff template in status proposed.
    static func newHandoffTemplate(_ code: String, name: String) -> HandoffTemplate {
        return HandoffTemplate(
            code: code,
            name: name,
            reviewer: "",
            revision: 0,
            channel: "",
            status: HandoffTemplateStatus.proposed
        )
    }
}
