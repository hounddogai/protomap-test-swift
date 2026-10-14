import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning adjustment is in its life cycle.
    enum CleaningAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One cleaning adjustment, with what the planners need to act on it.
    final class CleaningAdjustment {
        var code: String
        var label: String
        var quantity: Int
        var summary: String
        var maximum: Double
        var margin: Double
        var startsAt: Int
        var copay: Double
        var status: CleaningAdjustmentStatus

        init(code: String, label: String, quantity: Int, summary: String, maximum: Double, margin: Double, startsAt: Int, copay: Double, status: CleaningAdjustmentStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.summary = summary
            self.maximum = maximum
            self.margin = margin
            self.startsAt = startsAt
            self.copay = copay
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

        func canMoveTo(_ next: CleaningAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == CleaningAdjustmentStatus.pending || next == CleaningAdjustmentStatus.closed
            case .pending:
                return next == CleaningAdjustmentStatus.suspended
            case .active:
                return next == CleaningAdjustmentStatus.closed
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

        func moveTo(_ next: CleaningAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("cleaning adjustment") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(quantity) - copay) * 100).rounded() / 100
        }

        func copyValue() -> CleaningAdjustment {
            return CleaningAdjustment(
                code: code,
                label: label,
                quantity: quantity,
                summary: summary,
                maximum: maximum,
                margin: margin,
                startsAt: startsAt,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a cleaning adjustment in status draft.
    static func newCleaningAdjustment(_ code: String, label: String) -> CleaningAdjustment {
        return CleaningAdjustment(
            code: code,
            label: label,
            quantity: 0,
            summary: "",
            maximum: 0.0,
            margin: 0.0,
            startsAt: 0,
            copay: 0.0,
            status: CleaningAdjustmentStatus.draft
        )
    }
}
