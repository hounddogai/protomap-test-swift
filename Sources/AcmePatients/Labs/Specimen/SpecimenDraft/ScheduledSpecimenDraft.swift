import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled specimen draft is in its life cycle.
    enum ScheduledSpecimenDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled specimen draft as the specimen team keeps it.
    final class ScheduledSpecimenDraft {
        var code: String
        var title: String
        var tags: [String]
        var contactEmail: String
        var sequence: Int
        var facility: String
        var status: ScheduledSpecimenDraftStatus

        init(code: String, title: String, tags: [String], contactEmail: String, sequence: Int, facility: String, status: ScheduledSpecimenDraftStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.contactEmail = contactEmail
            self.sequence = sequence
            self.facility = facility
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

        func canMoveTo(_ next: ScheduledSpecimenDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ScheduledSpecimenDraftStatus.published
            case .published:
                return next == ScheduledSpecimenDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledSpecimenDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled specimen draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled specimen draft") \(code)"
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
            return Double(sequence)
        }

        func copyValue() -> ScheduledSpecimenDraft {
            return ScheduledSpecimenDraft(
                code: code,
                title: title,
                tags: tags,
                contactEmail: contactEmail,
                sequence: sequence,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a scheduled specimen draft in status created.
    static func newScheduledSpecimenDraft(_ code: String, title: String) -> ScheduledSpecimenDraft {
        return ScheduledSpecimenDraft(
            code: code,
            title: title,
            tags: [],
            contactEmail: "",
            sequence: 0,
            facility: "",
            status: ScheduledSpecimenDraftStatus.created
        )
    }
}
