import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall adjustment is in its life cycle.
    enum RecallAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A recall adjustment as the recall team keeps it.
    final class RecallAdjustment {
        var code: String
        var title: String
        var retries: Int
        var pinned: Bool
        var category: String
        var status: RecallAdjustmentStatus

        init(code: String, title: String, retries: Int, pinned: Bool, category: String, status: RecallAdjustmentStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.pinned = pinned
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RecallAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                return next == RecallAdjustmentStatus.retired
            case .validated:
                return next == RecallAdjustmentStatus.published || next == RecallAdjustmentStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RecallAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("recall adjustment") \(code)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> RecallAdjustment {
            return RecallAdjustment(
                code: code,
                title: title,
                retries: retries,
                pinned: pinned,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a recall adjustment in status created.
    static func newRecallAdjustment(_ code: String, title: String) -> RecallAdjustment {
        return RecallAdjustment(
            code: code,
            title: title,
            retries: 0,
            pinned: false,
            category: "",
            status: RecallAdjustmentStatus.created
        )
    }
}
