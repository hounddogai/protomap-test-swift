import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board snapshot is in its life cycle.
    enum BedBoardSnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a bed board snapshot and its current status.
    final class BedBoardSnapshot {
        var code: String
        var name: String
        var procedureCode: String
        var weight: Double
        var revision: Int
        var limit: Int
        var tags: [String]
        var graceDays: Int
        var archived: Bool
        var diagnosisCode: String
        var status: BedBoardSnapshotStatus

        init(code: String, name: String, procedureCode: String, weight: Double, revision: Int, limit: Int, tags: [String], graceDays: Int, archived: Bool, diagnosisCode: String, status: BedBoardSnapshotStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.weight = weight
            self.revision = revision
            self.limit = limit
            self.tags = tags
            self.graceDays = graceDays
            self.archived = archived
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BedBoardSnapshotStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == BedBoardSnapshotStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: BedBoardSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
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

        func weightedTotal() -> Double {
            return ((Double(limit) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardSnapshot {
            return BedBoardSnapshot(
                code: code,
                name: name,
                procedureCode: procedureCode,
                weight: weight,
                revision: revision,
                limit: limit,
                tags: tags,
                graceDays: graceDays,
                archived: archived,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a bed board snapshot in status planned.
    static func newBedBoardSnapshot(_ code: String, name: String) -> BedBoardSnapshot {
        return BedBoardSnapshot(
            code: code,
            name: name,
            procedureCode: "",
            weight: 0.0,
            revision: 0,
            limit: 0,
            tags: [],
            graceDays: 0,
            archived: false,
            diagnosisCode: "",
            status: BedBoardSnapshotStatus.planned
        )
    }
}
