import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff quota is in its life cycle.
    enum HandoffQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One handoff quota, with what the planners need to act on it.
    final class HandoffQuota {
        var code: String
        var name: String
        var tags: [String]
        var reviewer: String
        var expiresAt: Int
        var status: HandoffQuotaStatus

        init(code: String, name: String, tags: [String], reviewer: String, expiresAt: Int, status: HandoffQuotaStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.reviewer = reviewer
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: HandoffQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == HandoffQuotaStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: HandoffQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> HandoffQuota {
            return HandoffQuota(
                code: code,
                name: name,
                tags: tags,
                reviewer: reviewer,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a handoff quota in status created.
    static func newHandoffQuota(_ code: String, name: String) -> HandoffQuota {
        return HandoffQuota(
            code: code,
            name: name,
            tags: [],
            reviewer: "",
            expiresAt: 0,
            status: HandoffQuotaStatus.created
        )
    }
}
