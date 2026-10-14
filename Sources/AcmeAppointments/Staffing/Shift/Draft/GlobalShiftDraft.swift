import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global shift draft is in its life cycle.
    enum GlobalShiftDraftStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global shift draft. Its code is unique within a tenant.
    final class GlobalShiftDraft {
        var code: String
        var label: String
        var capacity: Int
        var approved: Bool
        var bed: String
        var startsAt: Int
        var windowDays: Int
        var status: GlobalShiftDraftStatus

        init(code: String, label: String, capacity: Int, approved: Bool, bed: String, startsAt: Int, windowDays: Int, status: GlobalShiftDraftStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.approved = approved
            self.bed = bed
            self.startsAt = startsAt
            self.windowDays = windowDays
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

        func canMoveTo(_ next: GlobalShiftDraftStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GlobalShiftDraftStatus.completed || next == GlobalShiftDraftStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: GlobalShiftDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global shift draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global shift draft") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(windowDays) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalShiftDraft {
            return GlobalShiftDraft(
                code: code,
                label: label,
                capacity: capacity,
                approved: approved,
                bed: bed,
                startsAt: startsAt,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global shift draft in status planned.
    static func newGlobalShiftDraft(_ code: String, label: String) -> GlobalShiftDraft {
        return GlobalShiftDraft(
            code: code,
            label: label,
            capacity: 0,
            approved: false,
            bed: "",
            startsAt: 0,
            windowDays: 0,
            status: GlobalShiftDraftStatus.planned
        )
    }
}
