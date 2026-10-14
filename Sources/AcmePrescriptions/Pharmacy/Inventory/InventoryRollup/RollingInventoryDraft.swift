import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling inventory draft is in its life cycle.
    enum RollingInventoryDraftStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a rolling inventory draft and its current status.
    final class RollingInventoryDraft {
        var code: String
        var label: String
        var archived: Bool
        var weight: Double
        var approved: Bool
        var procedureCode: String
        var endsAt: Int
        var revision: Int
        var status: RollingInventoryDraftStatus

        init(code: String, label: String, archived: Bool, weight: Double, approved: Bool, procedureCode: String, endsAt: Int, revision: Int, status: RollingInventoryDraftStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.weight = weight
            self.approved = approved
            self.procedureCode = procedureCode
            self.endsAt = endsAt
            self.revision = revision
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

        func canMoveTo(_ next: RollingInventoryDraftStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingInventoryDraftStatus.inProgress || next == RollingInventoryDraftStatus.completed
            case .scheduled:
                return next == RollingInventoryDraftStatus.completed || next == RollingInventoryDraftStatus.cancelled
            case .inProgress:
                return next == RollingInventoryDraftStatus.completed
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

        func moveTo(_ next: RollingInventoryDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling inventory draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("rolling inventory draft") \(code)"
        }

        func adjustedTotal() -> Double {
            return (weight * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> RollingInventoryDraft {
            return RollingInventoryDraft(
                code: code,
                label: label,
                archived: archived,
                weight: weight,
                approved: approved,
                procedureCode: procedureCode,
                endsAt: endsAt,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling inventory draft in status planned.
    static func newRollingInventoryDraft(_ code: String, label: String) -> RollingInventoryDraft {
        return RollingInventoryDraft(
            code: code,
            label: label,
            archived: false,
            weight: 0.0,
            approved: false,
            procedureCode: "",
            endsAt: 0,
            revision: 0,
            status: RollingInventoryDraftStatus.planned
        )
    }
}
