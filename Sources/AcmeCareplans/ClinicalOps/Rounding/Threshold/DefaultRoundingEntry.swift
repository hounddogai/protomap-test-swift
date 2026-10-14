import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default rounding entry is in its life cycle.
    enum DefaultRoundingEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default rounding entry. Its code is unique within a tenant.
    final class DefaultRoundingEntry {
        var code: String
        var name: String
        var updatedAt: Int
        var pinned: Bool
        var phone: String
        var summary: String
        var checksum: String
        var encounterID: String
        var visitMinutes: Int
        var archived: Bool
        var channel: String
        var status: DefaultRoundingEntryStatus

        init(code: String, name: String, updatedAt: Int, pinned: Bool, phone: String, summary: String, checksum: String, encounterID: String, visitMinutes: Int, archived: Bool, channel: String, status: DefaultRoundingEntryStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.pinned = pinned
            self.phone = phone
            self.summary = summary
            self.checksum = checksum
            self.encounterID = encounterID
            self.visitMinutes = visitMinutes
            self.archived = archived
            self.channel = channel
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

        func canMoveTo(_ next: DefaultRoundingEntryStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultRoundingEntryStatus.draining
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DefaultRoundingEntryStatus.draining || next == DefaultRoundingEntryStatus.stopped
            case .draining:
                return next == DefaultRoundingEntryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRoundingEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default rounding entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedLoad() -> Double {
            return ((Double(updatedAt) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRoundingEntry {
            return DefaultRoundingEntry(
                code: code,
                name: name,
                updatedAt: updatedAt,
                pinned: pinned,
                phone: phone,
                summary: summary,
                checksum: checksum,
                encounterID: encounterID,
                visitMinutes: visitMinutes,
                archived: archived,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a default rounding entry in status idle.
    static func newDefaultRoundingEntry(_ code: String, name: String) -> DefaultRoundingEntry {
        return DefaultRoundingEntry(
            code: code,
            name: name,
            updatedAt: 0,
            pinned: false,
            phone: "",
            summary: "",
            checksum: "",
            encounterID: "",
            visitMinutes: 0,
            archived: false,
            channel: "",
            status: DefaultRoundingEntryStatus.idle
        )
    }
}
