import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession snapshot is in its life cycle.
    enum AccessionSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A accession snapshot. Its code is unique within a tenant.
    final class AccessionSnapshot {
        var code: String
        var title: String
        var revision: Int
        var externalRef: String
        var notes: String
        var copay: Double
        var tags: [String]
        var dosageMg: Double
        var visitMinutes: Int
        var status: AccessionSnapshotStatus

        init(code: String, title: String, revision: Int, externalRef: String, notes: String, copay: Double, tags: [String], dosageMg: Double, visitMinutes: Int, status: AccessionSnapshotStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.externalRef = externalRef
            self.notes = notes
            self.copay = copay
            self.tags = tags
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: AccessionSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AccessionSnapshotStatus.archived
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

        func moveTo(_ next: AccessionSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("accession snapshot") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return (copay * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> AccessionSnapshot {
            return AccessionSnapshot(
                code: code,
                title: title,
                revision: revision,
                externalRef: externalRef,
                notes: notes,
                copay: copay,
                tags: tags,
                dosageMg: dosageMg,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession snapshot in status open.
    static func newAccessionSnapshot(_ code: String, title: String) -> AccessionSnapshot {
        return AccessionSnapshot(
            code: code,
            title: title,
            revision: 0,
            externalRef: "",
            notes: "",
            copay: 0.0,
            tags: [],
            dosageMg: 0.0,
            visitMinutes: 0,
            status: AccessionSnapshotStatus.`open`
        )
    }
}
