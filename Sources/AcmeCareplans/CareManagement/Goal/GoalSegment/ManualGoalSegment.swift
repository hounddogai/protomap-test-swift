import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual goal segment is in its life cycle.
    enum ManualGoalSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual goal segment as the goal team keeps it.
    final class ManualGoalSegment {
        var code: String
        var name: String
        var visible: Bool
        var title: String
        var attempts: Int
        var status: ManualGoalSegmentStatus

        init(code: String, name: String, visible: Bool, title: String, attempts: Int, status: ManualGoalSegmentStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.title = title
            self.attempts = attempts
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

        func canMoveTo(_ next: ManualGoalSegmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualGoalSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual goal segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> ManualGoalSegment {
            return ManualGoalSegment(
                code: code,
                name: name,
                visible: visible,
                title: title,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual goal segment in status created.
    static func newManualGoalSegment(_ code: String, name: String) -> ManualGoalSegment {
        return ManualGoalSegment(
            code: code,
            name: name,
            visible: false,
            title: "",
            attempts: 0,
            status: ManualGoalSegmentStatus.created
        )
    }
}
