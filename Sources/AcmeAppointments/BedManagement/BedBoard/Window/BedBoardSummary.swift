import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board summary is in its life cycle.
    enum BedBoardSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A bed board summary as the bed board team keeps it.
    final class BedBoardSummary {
        var code: String
        var title: String
        var weight: Double
        var encounterID: String
        var archived: Bool
        var pinned: Bool
        var bed: String
        var visitMinutes: Int
        var externalRef: String
        var updatedAt: Int
        var status: BedBoardSummaryStatus

        init(code: String, title: String, weight: Double, encounterID: String, archived: Bool, pinned: Bool, bed: String, visitMinutes: Int, externalRef: String, updatedAt: Int, status: BedBoardSummaryStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.encounterID = encounterID
            self.archived = archived
            self.pinned = pinned
            self.bed = bed
            self.visitMinutes = visitMinutes
            self.externalRef = externalRef
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: BedBoardSummaryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == BedBoardSummaryStatus.suspended || next == BedBoardSummaryStatus.closed
            case .suspended:
                return next == BedBoardSummaryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return ((weight - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardSummary {
            return BedBoardSummary(
                code: code,
                title: title,
                weight: weight,
                encounterID: encounterID,
                archived: archived,
                pinned: pinned,
                bed: bed,
                visitMinutes: visitMinutes,
                externalRef: externalRef,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a bed board summary in status draft.
    static func newBedBoardSummary(_ code: String, title: String) -> BedBoardSummary {
        return BedBoardSummary(
            code: code,
            title: title,
            weight: 0.0,
            encounterID: "",
            archived: false,
            pinned: false,
            bed: "",
            visitMinutes: 0,
            externalRef: "",
            updatedAt: 0,
            status: BedBoardSummaryStatus.draft
        )
    }
}
