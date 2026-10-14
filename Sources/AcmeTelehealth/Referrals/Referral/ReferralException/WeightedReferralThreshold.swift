import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted referral threshold is in its life cycle.
    enum WeightedReferralThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One weighted referral threshold, with what the planners need to act on it.
    final class WeightedReferralThreshold {
        var code: String
        var label: String
        var patientRef: String
        var graceDays: Int
        var batchSize: Int
        var ratio: Double
        var status: WeightedReferralThresholdStatus

        init(code: String, label: String, patientRef: String, graceDays: Int, batchSize: Int, ratio: Double, status: WeightedReferralThresholdStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.graceDays = graceDays
            self.batchSize = batchSize
            self.ratio = ratio
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

        func canMoveTo(_ next: WeightedReferralThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WeightedReferralThresholdStatus.archived
            case .resolved:
                return next == WeightedReferralThresholdStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: WeightedReferralThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted referral threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return (Double(batchSize) * ratio * 100).rounded() / 100
        }

        func copyValue() -> WeightedReferralThreshold {
            return WeightedReferralThreshold(
                code: code,
                label: label,
                patientRef: patientRef,
                graceDays: graceDays,
                batchSize: batchSize,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted referral threshold in status open.
    static func newWeightedReferralThreshold(_ code: String, label: String) -> WeightedReferralThreshold {
        return WeightedReferralThreshold(
            code: code,
            label: label,
            patientRef: "",
            graceDays: 0,
            batchSize: 0,
            ratio: 0.0,
            status: WeightedReferralThresholdStatus.`open`
        )
    }
}
