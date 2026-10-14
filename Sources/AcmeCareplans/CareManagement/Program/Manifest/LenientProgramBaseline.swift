import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient program baseline is in its life cycle.
    enum LenientProgramBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient program baseline as the program team keeps it.
    final class LenientProgramBaseline {
        var code: String
        var label: String
        var durationMinutes: Int
        var windowDays: Int
        var specialty: String
        var updatedAt: Int
        var retries: Int
        var visible: Bool
        var revision: Int
        var status: LenientProgramBaselineStatus

        init(code: String, label: String, durationMinutes: Int, windowDays: Int, specialty: String, updatedAt: Int, retries: Int, visible: Bool, revision: Int, status: LenientProgramBaselineStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
            self.specialty = specialty
            self.updatedAt = updatedAt
            self.retries = retries
            self.visible = visible
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientProgramBaselineStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientProgramBaselineStatus.stopped
            case .warming:
                return next == LenientProgramBaselineStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == LenientProgramBaselineStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientProgramBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient program baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(updatedAt) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LenientProgramBaseline {
            return LenientProgramBaseline(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                windowDays: windowDays,
                specialty: specialty,
                updatedAt: updatedAt,
                retries: retries,
                visible: visible,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient program baseline in status idle.
    static func newLenientProgramBaseline(_ code: String, label: String) -> LenientProgramBaseline {
        return LenientProgramBaseline(
            code: code,
            label: label,
            durationMinutes: 0,
            windowDays: 0,
            specialty: "",
            updatedAt: 0,
            retries: 0,
            visible: false,
            revision: 0,
            status: LenientProgramBaselineStatus.idle
        )
    }
}
