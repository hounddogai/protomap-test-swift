import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation mapping is in its life cycle.
    enum IsolationMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A isolation mapping. Its code is unique within a tenant.
    final class IsolationMapping {
        var code: String
        var title: String
        var weight: Double
        var cost: Double
        var margin: Double
        var pinned: Bool
        var copay: Double
        var discount: Double
        var visitMinutes: Int
        var status: IsolationMappingStatus

        init(code: String, title: String, weight: Double, cost: Double, margin: Double, pinned: Bool, copay: Double, discount: Double, visitMinutes: Int, status: IsolationMappingStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.cost = cost
            self.margin = margin
            self.pinned = pinned
            self.copay = copay
            self.discount = discount
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: IsolationMappingStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == IsolationMappingStatus.completed || next == IsolationMappingStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: IsolationMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedVolume() -> Double {
            return ((Double(visitMinutes) - copay) * 100).rounded() / 100
        }

        func copyValue() -> IsolationMapping {
            return IsolationMapping(
                code: code,
                title: title,
                weight: weight,
                cost: cost,
                margin: margin,
                pinned: pinned,
                copay: copay,
                discount: discount,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a isolation mapping in status planned.
    static func newIsolationMapping(_ code: String, title: String) -> IsolationMapping {
        return IsolationMapping(
            code: code,
            title: title,
            weight: 0.0,
            cost: 0.0,
            margin: 0.0,
            pinned: false,
            copay: 0.0,
            discount: 0.0,
            visitMinutes: 0,
            status: IsolationMappingStatus.planned
        )
    }
}
