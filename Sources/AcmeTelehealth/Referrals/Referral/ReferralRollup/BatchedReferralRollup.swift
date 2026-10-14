import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched referral rollup is in its life cycle.
    enum BatchedReferralRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One batched referral rollup, with what the planners need to act on it.
    final class BatchedReferralRollup {
        var code: String
        var label: String
        var reviewer: String
        var retries: Int
        var procedureCode: String
        var facility: String
        var score: Double
        var limit: Int
        var threshold: Double
        var refills: Int
        var endsAt: Int
        var status: BatchedReferralRollupStatus

        init(code: String, label: String, reviewer: String, retries: Int, procedureCode: String, facility: String, score: Double, limit: Int, threshold: Double, refills: Int, endsAt: Int, status: BatchedReferralRollupStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.retries = retries
            self.procedureCode = procedureCode
            self.facility = facility
            self.score = score
            self.limit = limit
            self.threshold = threshold
            self.refills = refills
            self.endsAt = endsAt
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

        func canMoveTo(_ next: BatchedReferralRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedReferralRollupStatus.suspended || next == BatchedReferralRollupStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: BatchedReferralRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched referral rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netVolume() -> Double {
            return ((Double(limit) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedReferralRollup {
            return BatchedReferralRollup(
                code: code,
                label: label,
                reviewer: reviewer,
                retries: retries,
                procedureCode: procedureCode,
                facility: facility,
                score: score,
                limit: limit,
                threshold: threshold,
                refills: refills,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a batched referral rollup in status draft.
    static func newBatchedReferralRollup(_ code: String, label: String) -> BatchedReferralRollup {
        return BatchedReferralRollup(
            code: code,
            label: label,
            reviewer: "",
            retries: 0,
            procedureCode: "",
            facility: "",
            score: 0.0,
            limit: 0,
            threshold: 0.0,
            refills: 0,
            endsAt: 0,
            status: BatchedReferralRollupStatus.draft
        )
    }
}
