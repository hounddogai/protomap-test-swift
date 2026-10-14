import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending charge draft is in its life cycle.
    enum PendingChargeDraftStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending charge draft as the charge team keeps it.
    final class PendingChargeDraft {
        var code: String
        var name: String
        var retries: Int
        var category: String
        var floorValue: Double
        var status: PendingChargeDraftStatus

        init(code: String, name: String, retries: Int, category: String, floorValue: Double, status: PendingChargeDraftStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.category = category
            self.floorValue = floorValue
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

        func canMoveTo(_ next: PendingChargeDraftStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingChargeDraftStatus.inProgress || next == PendingChargeDraftStatus.completed
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingChargeDraftStatus.cancelled
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

        func moveTo(_ next: PendingChargeDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending charge draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedLoad() -> Double {
            return ((floorValue + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PendingChargeDraft {
            return PendingChargeDraft(
                code: code,
                name: name,
                retries: retries,
                category: category,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending charge draft in status planned.
    static func newPendingChargeDraft(_ code: String, name: String) -> PendingChargeDraft {
        return PendingChargeDraft(
            code: code,
            name: name,
            retries: 0,
            category: "",
            floorValue: 0.0,
            status: PendingChargeDraftStatus.planned
        )
    }
}
