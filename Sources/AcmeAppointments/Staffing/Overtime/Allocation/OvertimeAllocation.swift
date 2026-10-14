import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime allocation is in its life cycle.
    enum OvertimeAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One overtime allocation, with what the planners need to act on it.
    final class OvertimeAllocation {
        var code: String
        var name: String
        var visible: Bool
        var payer: String
        var floorValue: Double
        var pinned: Bool
        var capacity: Int
        var facility: String
        var status: OvertimeAllocationStatus

        init(code: String, name: String, visible: Bool, payer: String, floorValue: Double, pinned: Bool, capacity: Int, facility: String, status: OvertimeAllocationStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.payer = payer
            self.floorValue = floorValue
            self.pinned = pinned
            self.capacity = capacity
            self.facility = facility
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

        func canMoveTo(_ next: OvertimeAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == OvertimeAllocationStatus.inReview
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: OvertimeAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return (Double(capacity) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> OvertimeAllocation {
            return OvertimeAllocation(
                code: code,
                name: name,
                visible: visible,
                payer: payer,
                floorValue: floorValue,
                pinned: pinned,
                capacity: capacity,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a overtime allocation in status open.
    static func newOvertimeAllocation(_ code: String, name: String) -> OvertimeAllocation {
        return OvertimeAllocation(
            code: code,
            name: name,
            visible: false,
            payer: "",
            floorValue: 0.0,
            pinned: false,
            capacity: 0,
            facility: "",
            status: OvertimeAllocationStatus.`open`
        )
    }
}
