import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending reference range batch is in its life cycle.
    enum PendingReferenceRangeBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending reference range batch. Its code is unique within a tenant.
    final class PendingReferenceRangeBatch {
        var code: String
        var title: String
        var allergy: String
        var refills: Int
        var minimum: Double
        var category: String
        var maximum: Double
        var discount: Double
        var visible: Bool
        var status: PendingReferenceRangeBatchStatus

        init(code: String, title: String, allergy: String, refills: Int, minimum: Double, category: String, maximum: Double, discount: Double, visible: Bool, status: PendingReferenceRangeBatchStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.refills = refills
            self.minimum = minimum
            self.category = category
            self.maximum = maximum
            self.discount = discount
            self.visible = visible
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

        func canMoveTo(_ next: PendingReferenceRangeBatchStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingReferenceRangeBatchStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PendingReferenceRangeBatchStatus.done || next == PendingReferenceRangeBatchStatus.failed
            case .done:
                return next == PendingReferenceRangeBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingReferenceRangeBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending reference range batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return ((minimum - maximum) * 100).rounded() / 100
        }

        func copyValue() -> PendingReferenceRangeBatch {
            return PendingReferenceRangeBatch(
                code: code,
                title: title,
                allergy: allergy,
                refills: refills,
                minimum: minimum,
                category: category,
                maximum: maximum,
                discount: discount,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending reference range batch in status new.
    static func newPendingReferenceRangeBatch(_ code: String, title: String) -> PendingReferenceRangeBatch {
        return PendingReferenceRangeBatch(
            code: code,
            title: title,
            allergy: "",
            refills: 0,
            minimum: 0.0,
            category: "",
            maximum: 0.0,
            discount: 0.0,
            visible: false,
            status: PendingReferenceRangeBatchStatus.new
        )
    }
}
