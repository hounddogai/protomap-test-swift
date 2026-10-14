import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled shift profile is in its life cycle.
    enum ScheduledShiftProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One scheduled shift profile, with what the planners need to act on it.
    final class ScheduledShiftProfile {
        var code: String
        var label: String
        var startsAt: Int
        var externalRef: String
        var checksum: String
        var tags: [String]
        var archived: Bool
        var ownerID: String
        var sequence: Int
        var title: String
        var createdAt: Int
        var status: ScheduledShiftProfileStatus

        init(code: String, label: String, startsAt: Int, externalRef: String, checksum: String, tags: [String], archived: Bool, ownerID: String, sequence: Int, title: String, createdAt: Int, status: ScheduledShiftProfileStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.externalRef = externalRef
            self.checksum = checksum
            self.tags = tags
            self.archived = archived
            self.ownerID = ownerID
            self.sequence = sequence
            self.title = title
            self.createdAt = createdAt
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

        func canMoveTo(_ next: ScheduledShiftProfileStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledShiftProfileStatus.ready || next == ScheduledShiftProfileStatus.draining
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ScheduledShiftProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledShiftProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled shift profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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
            return ((Double(startsAt) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledShiftProfile {
            return ScheduledShiftProfile(
                code: code,
                label: label,
                startsAt: startsAt,
                externalRef: externalRef,
                checksum: checksum,
                tags: tags,
                archived: archived,
                ownerID: ownerID,
                sequence: sequence,
                title: title,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled shift profile in status idle.
    static func newScheduledShiftProfile(_ code: String, label: String) -> ScheduledShiftProfile {
        return ScheduledShiftProfile(
            code: code,
            label: label,
            startsAt: 0,
            externalRef: "",
            checksum: "",
            tags: [],
            archived: false,
            ownerID: "",
            sequence: 0,
            title: "",
            createdAt: 0,
            status: ScheduledShiftProfileStatus.idle
        )
    }
}
