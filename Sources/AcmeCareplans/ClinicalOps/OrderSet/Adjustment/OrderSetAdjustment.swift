import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set adjustment is in its life cycle.
    enum OrderSetAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A order set adjustment. Its code is unique within a tenant.
    final class OrderSetAdjustment {
        var code: String
        var title: String
        var description: String
        var threshold: Double
        var floorValue: Double
        var visitMinutes: Int
        var margin: Double
        var status: OrderSetAdjustmentStatus

        init(code: String, title: String, description: String, threshold: Double, floorValue: Double, visitMinutes: Int, margin: Double, status: OrderSetAdjustmentStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.threshold = threshold
            self.floorValue = floorValue
            self.visitMinutes = visitMinutes
            self.margin = margin
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

        func canMoveTo(_ next: OrderSetAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == OrderSetAdjustmentStatus.completed || next == OrderSetAdjustmentStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == OrderSetAdjustmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return ((margin - threshold) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetAdjustment {
            return OrderSetAdjustment(
                code: code,
                title: title,
                description: description,
                threshold: threshold,
                floorValue: floorValue,
                visitMinutes: visitMinutes,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a order set adjustment in status planned.
    static func newOrderSetAdjustment(_ code: String, title: String) -> OrderSetAdjustment {
        return OrderSetAdjustment(
            code: code,
            title: title,
            description: "",
            threshold: 0.0,
            floorValue: 0.0,
            visitMinutes: 0,
            margin: 0.0,
            status: OrderSetAdjustmentStatus.planned
        )
    }
}
