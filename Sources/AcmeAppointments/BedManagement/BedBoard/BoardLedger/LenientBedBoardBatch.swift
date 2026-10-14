import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient bed board batch is in its life cycle.
    enum LenientBedBoardBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient bed board batch as the bed board team keeps it.
    final class LenientBedBoardBatch {
        var code: String
        var label: String
        var acuity: Int
        var quantity: Int
        var source: String
        var status: LenientBedBoardBatchStatus

        init(code: String, label: String, acuity: Int, quantity: Int, source: String, status: LenientBedBoardBatchStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.quantity = quantity
            self.source = source
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

        func canMoveTo(_ next: LenientBedBoardBatchStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientBedBoardBatchStatus.inReview
            case .inReview:
                return next == LenientBedBoardBatchStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LenientBedBoardBatchStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientBedBoardBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient bed board batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveValue() -> Double {
            return ((Double(quantity) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientBedBoardBatch {
            return LenientBedBoardBatch(
                code: code,
                label: label,
                acuity: acuity,
                quantity: quantity,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient bed board batch in status open.
    static func newLenientBedBoardBatch(_ code: String, label: String) -> LenientBedBoardBatch {
        return LenientBedBoardBatch(
            code: code,
            label: label,
            acuity: 0,
            quantity: 0,
            source: "",
            status: LenientBedBoardBatchStatus.`open`
        )
    }
}
