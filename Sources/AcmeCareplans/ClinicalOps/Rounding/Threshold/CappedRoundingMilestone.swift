import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped rounding milestone is in its life cycle.
    enum CappedRoundingMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a capped rounding milestone and its current status.
    final class CappedRoundingMilestone {
        var code: String
        var label: String
        var retries: Int
        var threshold: Double
        var currency: String
        var refills: Int
        var status: CappedRoundingMilestoneStatus

        init(code: String, label: String, retries: Int, threshold: Double, currency: String, refills: Int, status: CappedRoundingMilestoneStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.threshold = threshold
            self.currency = currency
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

        func canMoveTo(_ next: CappedRoundingMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedRoundingMilestoneStatus.active || next == CappedRoundingMilestoneStatus.closed
            case .pending:
                return next == CappedRoundingMilestoneStatus.suspended
            case .active:
                return next == CappedRoundingMilestoneStatus.suspended || next == CappedRoundingMilestoneStatus.closed
            case .suspended:
                return next == CappedRoundingMilestoneStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedRoundingMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped rounding milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedVolume() -> Double {
            return ((threshold - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> CappedRoundingMilestone {
            return CappedRoundingMilestone(
                code: code,
                label: label,
                retries: retries,
                threshold: threshold,
                currency: currency,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped rounding milestone in status draft.
    static func newCappedRoundingMilestone(_ code: String, label: String) -> CappedRoundingMilestone {
        return CappedRoundingMilestone(
            code: code,
            label: label,
            retries: 0,
            threshold: 0.0,
            currency: "",
            refills: 0,
            status: CappedRoundingMilestoneStatus.draft
        )
    }
}
