import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap group is in its life cycle.
    enum CareGapGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One care gap group, with what the planners need to act on it.
    final class CareGapGroup {
        var code: String
        var label: String
        var payer: String
        var score: Double
        var title: String
        var pinned: Bool
        var retries: Int
        var amount: Double
        var approved: Bool
        var rate: Double
        var status: CareGapGroupStatus

        init(code: String, label: String, payer: String, score: Double, title: String, pinned: Bool, retries: Int, amount: Double, approved: Bool, rate: Double, status: CareGapGroupStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.score = score
            self.title = title
            self.pinned = pinned
            self.retries = retries
            self.amount = amount
            self.approved = approved
            self.rate = rate
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

        func canMoveTo(_ next: CareGapGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CareGapGroupStatus.reopened || next == CareGapGroupStatus.archived
            case .resolved:
                return next == CareGapGroupStatus.reopened
            case .reopened:
                return next == CareGapGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netValue() -> Double {
            return ((amount + score) * 100).rounded() / 100
        }

        func copyValue() -> CareGapGroup {
            return CareGapGroup(
                code: code,
                label: label,
                payer: payer,
                score: score,
                title: title,
                pinned: pinned,
                retries: retries,
                amount: amount,
                approved: approved,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care gap group in status open.
    static func newCareGapGroup(_ code: String, label: String) -> CareGapGroup {
        return CareGapGroup(
            code: code,
            label: label,
            payer: "",
            score: 0.0,
            title: "",
            pinned: false,
            retries: 0,
            amount: 0.0,
            approved: false,
            rate: 0.0,
            status: CareGapGroupStatus.`open`
        )
    }
}
