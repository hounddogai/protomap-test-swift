import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered worklist entry is in its life cycle.
    enum TieredWorklistEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered worklist entry as the worklist team keeps it.
    final class TieredWorklistEntry {
        var code: String
        var title: String
        var maximum: Double
        var cost: Double
        var clinicianID: String
        var durationMinutes: Int
        var copay: Double
        var segment: String
        var bed: String
        var status: TieredWorklistEntryStatus

        init(code: String, title: String, maximum: Double, cost: Double, clinicianID: String, durationMinutes: Int, copay: Double, segment: String, bed: String, status: TieredWorklistEntryStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.cost = cost
            self.clinicianID = clinicianID
            self.durationMinutes = durationMinutes
            self.copay = copay
            self.segment = segment
            self.bed = bed
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

        func canMoveTo(_ next: TieredWorklistEntryStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredWorklistEntryStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == TieredWorklistEntryStatus.closed
            case .suspended:
                return next == TieredWorklistEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredWorklistEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered worklist entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedValue() -> Double {
            return ((cost + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredWorklistEntry {
            return TieredWorklistEntry(
                code: code,
                title: title,
                maximum: maximum,
                cost: cost,
                clinicianID: clinicianID,
                durationMinutes: durationMinutes,
                copay: copay,
                segment: segment,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a tiered worklist entry in status draft.
    static func newTieredWorklistEntry(_ code: String, title: String) -> TieredWorklistEntry {
        return TieredWorklistEntry(
            code: code,
            title: title,
            maximum: 0.0,
            cost: 0.0,
            clinicianID: "",
            durationMinutes: 0,
            copay: 0.0,
            segment: "",
            bed: "",
            status: TieredWorklistEntryStatus.draft
        )
    }
}
