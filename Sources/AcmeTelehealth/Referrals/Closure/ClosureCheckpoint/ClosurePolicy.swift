import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure policy is in its life cycle.
    enum ClosurePolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One closure policy, with what the planners need to act on it.
    final class ClosurePolicy {
        var code: String
        var label: String
        var visitMinutes: Int
        var notes: String
        var floorValue: Double
        var name: String
        var visible: Bool
        var ceiling: Double
        var status: ClosurePolicyStatus

        init(code: String, label: String, visitMinutes: Int, notes: String, floorValue: Double, name: String, visible: Bool, ceiling: Double, status: ClosurePolicyStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.notes = notes
            self.floorValue = floorValue
            self.name = name
            self.visible = visible
            self.ceiling = ceiling
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

        func canMoveTo(_ next: ClosurePolicyStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ClosurePolicyStatus.published || next == ClosurePolicyStatus.retired
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

        func moveTo(_ next: ClosurePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return ((floorValue - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ClosurePolicy {
            return ClosurePolicy(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                notes: notes,
                floorValue: floorValue,
                name: name,
                visible: visible,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a closure policy in status created.
    static func newClosurePolicy(_ code: String, label: String) -> ClosurePolicy {
        return ClosurePolicy(
            code: code,
            label: label,
            visitMinutes: 0,
            notes: "",
            floorValue: 0.0,
            name: "",
            visible: false,
            ceiling: 0.0,
            status: ClosurePolicyStatus.created
        )
    }
}
