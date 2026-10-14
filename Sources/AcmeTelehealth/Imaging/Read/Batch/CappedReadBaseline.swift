import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped read baseline is in its life cycle.
    enum CappedReadBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a capped read baseline and its current status.
    final class CappedReadBaseline {
        var code: String
        var name: String
        var amount: Double
        var threshold: Double
        var bed: String
        var category: String
        var sequence: Int
        var minimum: Double
        var externalRef: String
        var status: CappedReadBaselineStatus

        init(code: String, name: String, amount: Double, threshold: Double, bed: String, category: String, sequence: Int, minimum: Double, externalRef: String, status: CappedReadBaselineStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.threshold = threshold
            self.bed = bed
            self.category = category
            self.sequence = sequence
            self.minimum = minimum
            self.externalRef = externalRef
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

        func canMoveTo(_ next: CappedReadBaselineStatus) -> Bool {
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
                return next == CappedReadBaselineStatus.resolved || next == CappedReadBaselineStatus.archived
            case .resolved:
                return next == CappedReadBaselineStatus.archived
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

        func moveTo(_ next: CappedReadBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped read baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped read baseline") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((amount - minimum) * 100).rounded() / 100
        }

        func copyValue() -> CappedReadBaseline {
            return CappedReadBaseline(
                code: code,
                name: name,
                amount: amount,
                threshold: threshold,
                bed: bed,
                category: category,
                sequence: sequence,
                minimum: minimum,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a capped read baseline in status open.
    static func newCappedReadBaseline(_ code: String, name: String) -> CappedReadBaseline {
        return CappedReadBaseline(
            code: code,
            name: name,
            amount: 0.0,
            threshold: 0.0,
            bed: "",
            category: "",
            sequence: 0,
            minimum: 0.0,
            externalRef: "",
            status: CappedReadBaselineStatus.`open`
        )
    }
}
