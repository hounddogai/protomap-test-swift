import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range variance is in its life cycle.
    enum ReferenceRangeVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A reference range variance. Its code is unique within a tenant.
    final class ReferenceRangeVariance {
        var code: String
        var title: String
        var notes: String
        var quantity: Int
        var currency: String
        var limit: Int
        var externalRef: String
        var status: ReferenceRangeVarianceStatus

        init(code: String, title: String, notes: String, quantity: Int, currency: String, limit: Int, externalRef: String, status: ReferenceRangeVarianceStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.quantity = quantity
            self.currency = currency
            self.limit = limit
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeVarianceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ReferenceRangeVarianceStatus.failed
            case .running:
                return next == ReferenceRangeVarianceStatus.done || next == ReferenceRangeVarianceStatus.failed
            case .done:
                return next == ReferenceRangeVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return ((Double(quantity) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeVariance {
            return ReferenceRangeVariance(
                code: code,
                title: title,
                notes: notes,
                quantity: quantity,
                currency: currency,
                limit: limit,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a reference range variance in status new.
    static func newReferenceRangeVariance(_ code: String, title: String) -> ReferenceRangeVariance {
        return ReferenceRangeVariance(
            code: code,
            title: title,
            notes: "",
            quantity: 0,
            currency: "",
            limit: 0,
            externalRef: "",
            status: ReferenceRangeVarianceStatus.new
        )
    }
}
