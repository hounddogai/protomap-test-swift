import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool group is in its life cycle.
    enum FloatPoolGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A float pool group. Its code is unique within a tenant.
    final class FloatPoolGroup {
        var code: String
        var label: String
        var pinned: Bool
        var graceDays: Int
        var limit: Int
        var active: Bool
        var visible: Bool
        var capacity: Int
        var sequence: Int
        var status: FloatPoolGroupStatus

        init(code: String, label: String, pinned: Bool, graceDays: Int, limit: Int, active: Bool, visible: Bool, capacity: Int, sequence: Int, status: FloatPoolGroupStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.graceDays = graceDays
            self.limit = limit
            self.active = active
            self.visible = visible
            self.capacity = capacity
            self.sequence = sequence
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

        func canMoveTo(_ next: FloatPoolGroupStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FloatPoolGroupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netTotal() -> Double {
            return ((Double(limit) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolGroup {
            return FloatPoolGroup(
                code: code,
                label: label,
                pinned: pinned,
                graceDays: graceDays,
                limit: limit,
                active: active,
                visible: visible,
                capacity: capacity,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool group in status planned.
    static func newFloatPoolGroup(_ code: String, label: String) -> FloatPoolGroup {
        return FloatPoolGroup(
            code: code,
            label: label,
            pinned: false,
            graceDays: 0,
            limit: 0,
            active: false,
            visible: false,
            capacity: 0,
            sequence: 0,
            status: FloatPoolGroupStatus.planned
        )
    }
}
