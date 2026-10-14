import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance review is in its life cycle.
    enum RemittanceReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One remittance review, with what the planners need to act on it.
    final class RemittanceReview {
        var code: String
        var title: String
        var graceDays: Int
        var margin: Double
        var refills: Int
        var status: RemittanceReviewStatus

        init(code: String, title: String, graceDays: Int, margin: Double, refills: Int, status: RemittanceReviewStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.margin = margin
            self.refills = refills
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

        func canMoveTo(_ next: RemittanceReviewStatus) -> Bool {
            switch status {
            case .draft:
                return next == RemittanceReviewStatus.suspended
            case .pending:
                return next == RemittanceReviewStatus.active || next == RemittanceReviewStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RemittanceReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return ((Double(refills) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceReview {
            return RemittanceReview(
                code: code,
                title: title,
                graceDays: graceDays,
                margin: margin,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a remittance review in status draft.
    static func newRemittanceReview(_ code: String, title: String) -> RemittanceReview {
        return RemittanceReview(
            code: code,
            title: title,
            graceDays: 0,
            margin: 0.0,
            refills: 0,
            status: RemittanceReviewStatus.draft
        )
    }
}
