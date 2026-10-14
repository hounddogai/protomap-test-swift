import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set review is in its life cycle.
    enum OrderSetReviewStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A order set review. Its code is unique within a tenant.
    final class OrderSetReview {
        var code: String
        var label: String
        var payer: String
        var patientRef: String
        var name: String
        var rate: Double
        var copay: Double
        var status: OrderSetReviewStatus

        init(code: String, label: String, payer: String, patientRef: String, name: String, rate: Double, copay: Double, status: OrderSetReviewStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.patientRef = patientRef
            self.name = name
            self.rate = rate
            self.copay = copay
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

        func canMoveTo(_ next: OrderSetReviewStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == OrderSetReviewStatus.inProgress || next == OrderSetReviewStatus.completed
            case .inProgress:
                return next == OrderSetReviewStatus.completed
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

        func moveTo(_ next: OrderSetReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((copay + rate) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetReview {
            return OrderSetReview(
                code: code,
                label: label,
                payer: payer,
                patientRef: patientRef,
                name: name,
                rate: rate,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a order set review in status planned.
    static func newOrderSetReview(_ code: String, label: String) -> OrderSetReview {
        return OrderSetReview(
            code: code,
            label: label,
            payer: "",
            patientRef: "",
            name: "",
            rate: 0.0,
            copay: 0.0,
            status: OrderSetReviewStatus.planned
        )
    }
}
