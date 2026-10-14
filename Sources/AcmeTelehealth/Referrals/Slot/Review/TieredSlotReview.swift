import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered slot review is in its life cycle.
    enum TieredSlotReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One tiered slot review, with what the planners need to act on it.
    final class TieredSlotReview {
        var code: String
        var title: String
        var bed: String
        var copay: Double
        var checksum: String
        var priority: Int
        var budget: Double
        var specialty: String
        var summary: String
        var status: TieredSlotReviewStatus

        init(code: String, title: String, bed: String, copay: Double, checksum: String, priority: Int, budget: Double, specialty: String, summary: String, status: TieredSlotReviewStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.copay = copay
            self.checksum = checksum
            self.priority = priority
            self.budget = budget
            self.specialty = specialty
            self.summary = summary
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

        func canMoveTo(_ next: TieredSlotReviewStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredSlotReviewStatus.pending
            case .pending:
                return next == TieredSlotReviewStatus.active || next == TieredSlotReviewStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredSlotReviewStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredSlotReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered slot review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered slot review") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(priority) - budget) * 100).rounded() / 100
        }

        func copyValue() -> TieredSlotReview {
            return TieredSlotReview(
                code: code,
                title: title,
                bed: bed,
                copay: copay,
                checksum: checksum,
                priority: priority,
                budget: budget,
                specialty: specialty,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered slot review in status draft.
    static func newTieredSlotReview(_ code: String, title: String) -> TieredSlotReview {
        return TieredSlotReview(
            code: code,
            title: title,
            bed: "",
            copay: 0.0,
            checksum: "",
            priority: 0,
            budget: 0.0,
            specialty: "",
            summary: "",
            status: TieredSlotReviewStatus.draft
        )
    }
}
