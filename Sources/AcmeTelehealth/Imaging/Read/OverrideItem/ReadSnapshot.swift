import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read snapshot is in its life cycle.
    enum ReadSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A read snapshot as the read team keeps it.
    final class ReadSnapshot {
        var code: String
        var title: String
        var procedureCode: String
        var specialty: String
        var revision: Int
        var contactEmail: String
        var reviewer: String
        var bed: String
        var status: ReadSnapshotStatus

        init(code: String, title: String, procedureCode: String, specialty: String, revision: Int, contactEmail: String, reviewer: String, bed: String, status: ReadSnapshotStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.revision = revision
            self.contactEmail = contactEmail
            self.reviewer = reviewer
            self.bed = bed
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

        func canMoveTo(_ next: ReadSnapshotStatus) -> Bool {
            switch status {
            case .created:
                return next == ReadSnapshotStatus.published
            case .validated:
                return next == ReadSnapshotStatus.published
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

        func moveTo(_ next: ReadSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> ReadSnapshot {
            return ReadSnapshot(
                code: code,
                title: title,
                procedureCode: procedureCode,
                specialty: specialty,
                revision: revision,
                contactEmail: contactEmail,
                reviewer: reviewer,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a read snapshot in status created.
    static func newReadSnapshot(_ code: String, title: String) -> ReadSnapshot {
        return ReadSnapshot(
            code: code,
            title: title,
            procedureCode: "",
            specialty: "",
            revision: 0,
            contactEmail: "",
            reviewer: "",
            bed: "",
            status: ReadSnapshotStatus.created
        )
    }
}
