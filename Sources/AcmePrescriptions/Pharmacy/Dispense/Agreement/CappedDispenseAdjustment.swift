import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped dispense adjustment is in its life cycle.
    enum CappedDispenseAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped dispense adjustment. Its code is unique within a tenant.
    final class CappedDispenseAdjustment {
        var code: String
        var title: String
        var floorValue: Double
        var cost: Double
        var updatedAt: Int
        var status: CappedDispenseAdjustmentStatus

        init(code: String, title: String, floorValue: Double, cost: Double, updatedAt: Int, status: CappedDispenseAdjustmentStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.cost = cost
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: CappedDispenseAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedDispenseAdjustmentStatus.failed
            case .queued:
                return next == CappedDispenseAdjustmentStatus.running || next == CappedDispenseAdjustmentStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CappedDispenseAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped dispense adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return (Double(updatedAt) * cost * 100).rounded() / 100
        }

        func copyValue() -> CappedDispenseAdjustment {
            return CappedDispenseAdjustment(
                code: code,
                title: title,
                floorValue: floorValue,
                cost: cost,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped dispense adjustment in status new.
    static func newCappedDispenseAdjustment(_ code: String, title: String) -> CappedDispenseAdjustment {
        return CappedDispenseAdjustment(
            code: code,
            title: title,
            floorValue: 0.0,
            cost: 0.0,
            updatedAt: 0,
            status: CappedDispenseAdjustmentStatus.new
        )
    }
}
