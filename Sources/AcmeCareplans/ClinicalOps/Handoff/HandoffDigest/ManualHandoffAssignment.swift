import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual handoff assignment is in its life cycle.
    enum ManualHandoffAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One manual handoff assignment, with what the planners need to act on it.
    final class ManualHandoffAssignment {
        var code: String
        var name: String
        var visible: Bool
        var channel: String
        var expiresAt: Int
        var status: ManualHandoffAssignmentStatus

        init(code: String, name: String, visible: Bool, channel: String, expiresAt: Int, status: ManualHandoffAssignmentStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.channel = channel
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: ManualHandoffAssignmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ManualHandoffAssignmentStatus.running || next == ManualHandoffAssignmentStatus.done
            case .running:
                return next == ManualHandoffAssignmentStatus.done || next == ManualHandoffAssignmentStatus.failed
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

        func moveTo(_ next: ManualHandoffAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual handoff assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> ManualHandoffAssignment {
            return ManualHandoffAssignment(
                code: code,
                name: name,
                visible: visible,
                channel: channel,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a manual handoff assignment in status new.
    static func newManualHandoffAssignment(_ code: String, name: String) -> ManualHandoffAssignment {
        return ManualHandoffAssignment(
            code: code,
            name: name,
            visible: false,
            channel: "",
            expiresAt: 0,
            status: ManualHandoffAssignmentStatus.new
        )
    }
}
