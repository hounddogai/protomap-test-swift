import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched goal baseline is in its life cycle.
    enum BatchedGoalBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One batched goal baseline, with what the planners need to act on it.
    final class BatchedGoalBaseline {
        var code: String
        var title: String
        var clinicianID: String
        var payer: String
        var ratio: Double
        var revision: Int
        var rate: Double
        var expiresAt: Int
        var refills: Int
        var status: BatchedGoalBaselineStatus

        init(code: String, title: String, clinicianID: String, payer: String, ratio: Double, revision: Int, rate: Double, expiresAt: Int, refills: Int, status: BatchedGoalBaselineStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.payer = payer
            self.ratio = ratio
            self.revision = revision
            self.rate = rate
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: BatchedGoalBaselineStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedGoalBaselineStatus.pending || next == BatchedGoalBaselineStatus.active
            case .pending:
                return next == BatchedGoalBaselineStatus.suspended
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

        func moveTo(_ next: BatchedGoalBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched goal baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("batched goal baseline") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(refills) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedGoalBaseline {
            return BatchedGoalBaseline(
                code: code,
                title: title,
                clinicianID: clinicianID,
                payer: payer,
                ratio: ratio,
                revision: revision,
                rate: rate,
                expiresAt: expiresAt,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched goal baseline in status draft.
    static func newBatchedGoalBaseline(_ code: String, title: String) -> BatchedGoalBaseline {
        return BatchedGoalBaseline(
            code: code,
            title: title,
            clinicianID: "",
            payer: "",
            ratio: 0.0,
            revision: 0,
            rate: 0.0,
            expiresAt: 0,
            refills: 0,
            status: BatchedGoalBaselineStatus.draft
        )
    }
}
