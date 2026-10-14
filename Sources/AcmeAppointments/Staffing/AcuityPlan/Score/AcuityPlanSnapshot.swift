import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan snapshot is in its life cycle.
    enum AcuityPlanSnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A acuity plan snapshot as the acuity plan team keeps it.
    final class AcuityPlanSnapshot {
        var code: String
        var name: String
        var tags: [String]
        var archived: Bool
        var revision: Int
        var phone: String
        var dosageMg: Double
        var segment: String
        var status: AcuityPlanSnapshotStatus

        init(code: String, name: String, tags: [String], archived: Bool, revision: Int, phone: String, dosageMg: Double, segment: String, status: AcuityPlanSnapshotStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.archived = archived
            self.revision = revision
            self.phone = phone
            self.dosageMg = dosageMg
            self.segment = segment
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

        func canMoveTo(_ next: AcuityPlanSnapshotStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AcuityPlanSnapshotStatus.closed
            case .active:
                return next == AcuityPlanSnapshotStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: AcuityPlanSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
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
            return ((dosageMg - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanSnapshot {
            return AcuityPlanSnapshot(
                code: code,
                name: name,
                tags: tags,
                archived: archived,
                revision: revision,
                phone: phone,
                dosageMg: dosageMg,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a acuity plan snapshot in status draft.
    static func newAcuityPlanSnapshot(_ code: String, name: String) -> AcuityPlanSnapshot {
        return AcuityPlanSnapshot(
            code: code,
            name: name,
            tags: [],
            archived: false,
            revision: 0,
            phone: "",
            dosageMg: 0.0,
            segment: "",
            status: AcuityPlanSnapshotStatus.draft
        )
    }
}
