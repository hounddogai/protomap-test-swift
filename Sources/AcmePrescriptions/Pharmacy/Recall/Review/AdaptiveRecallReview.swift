import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive recall review is in its life cycle.
    enum AdaptiveRecallReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive recall review. Its code is unique within a tenant.
    final class AdaptiveRecallReview {
        var code: String
        var title: String
        var batchSize: Int
        var maximum: Double
        var label: String
        var procedureCode: String
        var cost: Double
        var patientRef: String
        var status: AdaptiveRecallReviewStatus

        init(code: String, title: String, batchSize: Int, maximum: Double, label: String, procedureCode: String, cost: Double, patientRef: String, status: AdaptiveRecallReviewStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.maximum = maximum
            self.label = label
            self.procedureCode = procedureCode
            self.cost = cost
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveRecallReviewStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveRecallReviewStatus.approved || next == AdaptiveRecallReviewStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveRecallReviewStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRecallReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive recall review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func weightedTotal() -> Double {
            return ((maximum - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRecallReview {
            return AdaptiveRecallReview(
                code: code,
                title: title,
                batchSize: batchSize,
                maximum: maximum,
                label: label,
                procedureCode: procedureCode,
                cost: cost,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive recall review in status proposed.
    static func newAdaptiveRecallReview(_ code: String, title: String) -> AdaptiveRecallReview {
        return AdaptiveRecallReview(
            code: code,
            title: title,
            batchSize: 0,
            maximum: 0.0,
            label: "",
            procedureCode: "",
            cost: 0.0,
            patientRef: "",
            status: AdaptiveRecallReviewStatus.proposed
        )
    }
}
