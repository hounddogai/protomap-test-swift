import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global interaction assignment is in its life cycle.
    enum GlobalInteractionAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a global interaction assignment and its current status.
    final class GlobalInteractionAssignment {
        var code: String
        var title: String
        var contactEmail: String
        var procedureCode: String
        var windowDays: Int
        var channel: String
        var diagnosisCode: String
        var pinned: Bool
        var capacity: Int
        var revision: Int
        var priority: Int
        var status: GlobalInteractionAssignmentStatus

        init(code: String, title: String, contactEmail: String, procedureCode: String, windowDays: Int, channel: String, diagnosisCode: String, pinned: Bool, capacity: Int, revision: Int, priority: Int, status: GlobalInteractionAssignmentStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.procedureCode = procedureCode
            self.windowDays = windowDays
            self.channel = channel
            self.diagnosisCode = diagnosisCode
            self.pinned = pinned
            self.capacity = capacity
            self.revision = revision
            self.priority = priority
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

        func canMoveTo(_ next: GlobalInteractionAssignmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == GlobalInteractionAssignmentStatus.running
            case .running:
                return next == GlobalInteractionAssignmentStatus.failed
            case .done:
                return next == GlobalInteractionAssignmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalInteractionAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global interaction assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(windowDays) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalInteractionAssignment {
            return GlobalInteractionAssignment(
                code: code,
                title: title,
                contactEmail: contactEmail,
                procedureCode: procedureCode,
                windowDays: windowDays,
                channel: channel,
                diagnosisCode: diagnosisCode,
                pinned: pinned,
                capacity: capacity,
                revision: revision,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global interaction assignment in status new.
    static func newGlobalInteractionAssignment(_ code: String, title: String) -> GlobalInteractionAssignment {
        return GlobalInteractionAssignment(
            code: code,
            title: title,
            contactEmail: "",
            procedureCode: "",
            windowDays: 0,
            channel: "",
            diagnosisCode: "",
            pinned: false,
            capacity: 0,
            revision: 0,
            priority: 0,
            status: GlobalInteractionAssignmentStatus.new
        )
    }
}
