import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up score is in its life cycle.
    enum FollowUpScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A follow up score as the follow up team keeps it.
    final class FollowUpScore {
        var code: String
        var label: String
        var amount: Double
        var retries: Int
        var batchSize: Int
        var country: String
        var bed: String
        var status: FollowUpScoreStatus

        init(code: String, label: String, amount: Double, retries: Int, batchSize: Int, country: String, bed: String, status: FollowUpScoreStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.retries = retries
            self.batchSize = batchSize
            self.country = country
            self.bed = bed
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

        func canMoveTo(_ next: FollowUpScoreStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == FollowUpScoreStatus.cancelled
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

        func moveTo(_ next: FollowUpScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("follow up score") \(code)"
        }

        func weightedExposure() -> Double {
            return ((amount + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpScore {
            return FollowUpScore(
                code: code,
                label: label,
                amount: amount,
                retries: retries,
                batchSize: batchSize,
                country: country,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a follow up score in status planned.
    static func newFollowUpScore(_ code: String, label: String) -> FollowUpScore {
        return FollowUpScore(
            code: code,
            label: label,
            amount: 0.0,
            retries: 0,
            batchSize: 0,
            country: "",
            bed: "",
            status: FollowUpScoreStatus.planned
        )
    }
}
