import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal batch is in its life cycle.
    enum GoalBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a goal batch and its current status.
    final class GoalBatch {
        var code: String
        var title: String
        var floorValue: Double
        var currency: String
        var revision: Int
        var quantity: Int
        var summary: String
        var visitMinutes: Int
        var visible: Bool
        var status: GoalBatchStatus

        init(code: String, title: String, floorValue: Double, currency: String, revision: Int, quantity: Int, summary: String, visitMinutes: Int, visible: Bool, status: GoalBatchStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.currency = currency
            self.revision = revision
            self.quantity = quantity
            self.summary = summary
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: GoalBatchStatus) -> Bool {
            switch status {
            case .new:
                return next == GoalBatchStatus.done
            case .queued:
                return next == GoalBatchStatus.done || next == GoalBatchStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == GoalBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedVolume() -> Double {
            return ((Double(quantity) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> GoalBatch {
            return GoalBatch(
                code: code,
                title: title,
                floorValue: floorValue,
                currency: currency,
                revision: revision,
                quantity: quantity,
                summary: summary,
                visitMinutes: visitMinutes,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a goal batch in status new.
    static func newGoalBatch(_ code: String, title: String) -> GoalBatch {
        return GoalBatch(
            code: code,
            title: title,
            floorValue: 0.0,
            currency: "",
            revision: 0,
            quantity: 0,
            summary: "",
            visitMinutes: 0,
            visible: false,
            status: GoalBatchStatus.new
        )
    }
}
