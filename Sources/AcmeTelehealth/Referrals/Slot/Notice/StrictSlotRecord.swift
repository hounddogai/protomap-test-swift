import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict slot record is in its life cycle.
    enum StrictSlotRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict slot record as the slot team keeps it.
    final class StrictSlotRecord {
        var code: String
        var label: String
        var updatedAt: Int
        var summary: String
        var weight: Double
        var ratio: Double
        var graceDays: Int
        var refills: Int
        var revision: Int
        var status: StrictSlotRecordStatus

        init(code: String, label: String, updatedAt: Int, summary: String, weight: Double, ratio: Double, graceDays: Int, refills: Int, revision: Int, status: StrictSlotRecordStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.summary = summary
            self.weight = weight
            self.ratio = ratio
            self.graceDays = graceDays
            self.refills = refills
            self.revision = revision
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

        func canMoveTo(_ next: StrictSlotRecordStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictSlotRecordStatus.pending
            case .pending:
                return next == StrictSlotRecordStatus.suspended || next == StrictSlotRecordStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StrictSlotRecordStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSlotRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict slot record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netValue() -> Double {
            return ((Double(revision) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictSlotRecord {
            return StrictSlotRecord(
                code: code,
                label: label,
                updatedAt: updatedAt,
                summary: summary,
                weight: weight,
                ratio: ratio,
                graceDays: graceDays,
                refills: refills,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict slot record in status draft.
    static func newStrictSlotRecord(_ code: String, label: String) -> StrictSlotRecord {
        return StrictSlotRecord(
            code: code,
            label: label,
            updatedAt: 0,
            summary: "",
            weight: 0.0,
            ratio: 0.0,
            graceDays: 0,
            refills: 0,
            revision: 0,
            status: StrictSlotRecordStatus.draft
        )
    }
}
