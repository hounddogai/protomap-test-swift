import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff digest is in its life cycle.
    enum HandoffDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a handoff digest and its current status.
    final class HandoffDigest {
        var code: String
        var label: String
        var visible: Bool
        var version: Int
        var endsAt: Int
        var expiresAt: Int
        var archived: Bool
        var tags: [String]
        var createdAt: Int
        var notes: String
        var channel: String
        var status: HandoffDigestStatus

        init(code: String, label: String, visible: Bool, version: Int, endsAt: Int, expiresAt: Int, archived: Bool, tags: [String], createdAt: Int, notes: String, channel: String, status: HandoffDigestStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.version = version
            self.endsAt = endsAt
            self.expiresAt = expiresAt
            self.archived = archived
            self.tags = tags
            self.createdAt = createdAt
            self.notes = notes
            self.channel = channel
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

        func canMoveTo(_ next: HandoffDigestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == HandoffDigestStatus.closed
            case .active:
                return next == HandoffDigestStatus.suspended || next == HandoffDigestStatus.closed
            case .suspended:
                return next == HandoffDigestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return ((Double(createdAt) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffDigest {
            return HandoffDigest(
                code: code,
                label: label,
                visible: visible,
                version: version,
                endsAt: endsAt,
                expiresAt: expiresAt,
                archived: archived,
                tags: tags,
                createdAt: createdAt,
                notes: notes,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a handoff digest in status draft.
    static func newHandoffDigest(_ code: String, label: String) -> HandoffDigest {
        return HandoffDigest(
            code: code,
            label: label,
            visible: false,
            version: 0,
            endsAt: 0,
            expiresAt: 0,
            archived: false,
            tags: [],
            createdAt: 0,
            notes: "",
            channel: "",
            status: HandoffDigestStatus.draft
        )
    }
}
