import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession adjustment is in its life cycle.
    enum AccessionAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A accession adjustment as the accession team keeps it.
    final class AccessionAdjustment {
        var code: String
        var title: String
        var capacity: Int
        var discount: Double
        var retries: Int
        var score: Double
        var reviewer: String
        var graceDays: Int
        var approved: Bool
        var facility: String
        var status: AccessionAdjustmentStatus

        init(code: String, title: String, capacity: Int, discount: Double, retries: Int, score: Double, reviewer: String, graceDays: Int, approved: Bool, facility: String, status: AccessionAdjustmentStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.discount = discount
            self.retries = retries
            self.score = score
            self.reviewer = reviewer
            self.graceDays = graceDays
            self.approved = approved
            self.facility = facility
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

        func canMoveTo(_ next: AccessionAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AccessionAdjustmentStatus.active || next == AccessionAdjustmentStatus.suspended
            case .active:
                return next == AccessionAdjustmentStatus.suspended || next == AccessionAdjustmentStatus.closed
            case .suspended:
                return next == AccessionAdjustmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedValue() -> Double {
            return (Double(retries) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> AccessionAdjustment {
            return AccessionAdjustment(
                code: code,
                title: title,
                capacity: capacity,
                discount: discount,
                retries: retries,
                score: score,
                reviewer: reviewer,
                graceDays: graceDays,
                approved: approved,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a accession adjustment in status draft.
    static func newAccessionAdjustment(_ code: String, title: String) -> AccessionAdjustment {
        return AccessionAdjustment(
            code: code,
            title: title,
            capacity: 0,
            discount: 0.0,
            retries: 0,
            score: 0.0,
            reviewer: "",
            graceDays: 0,
            approved: false,
            facility: "",
            status: AccessionAdjustmentStatus.draft
        )
    }
}
