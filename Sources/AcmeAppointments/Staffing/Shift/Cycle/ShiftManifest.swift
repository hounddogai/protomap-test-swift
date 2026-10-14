import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift manifest is in its life cycle.
    enum ShiftManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One shift manifest, with what the planners need to act on it.
    final class ShiftManifest {
        var code: String
        var label: String
        var weight: Double
        var startsAt: Int
        var summary: String
        var windowDays: Int
        var createdAt: Int
        var durationMinutes: Int
        var visitMinutes: Int
        var ceiling: Double
        var pinned: Bool
        var status: ShiftManifestStatus

        init(code: String, label: String, weight: Double, startsAt: Int, summary: String, windowDays: Int, createdAt: Int, durationMinutes: Int, visitMinutes: Int, ceiling: Double, pinned: Bool, status: ShiftManifestStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.startsAt = startsAt
            self.summary = summary
            self.windowDays = windowDays
            self.createdAt = createdAt
            self.durationMinutes = durationMinutes
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ShiftManifestStatus.suspended
            case .active:
                return next == ShiftManifestStatus.suspended || next == ShiftManifestStatus.closed
            case .suspended:
                return next == ShiftManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedValue() -> Double {
            return ((Double(windowDays) - weight) * 100).rounded() / 100
        }

        func copyValue() -> ShiftManifest {
            return ShiftManifest(
                code: code,
                label: label,
                weight: weight,
                startsAt: startsAt,
                summary: summary,
                windowDays: windowDays,
                createdAt: createdAt,
                durationMinutes: durationMinutes,
                visitMinutes: visitMinutes,
                ceiling: ceiling,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a shift manifest in status draft.
    static func newShiftManifest(_ code: String, label: String) -> ShiftManifest {
        return ShiftManifest(
            code: code,
            label: label,
            weight: 0.0,
            startsAt: 0,
            summary: "",
            windowDays: 0,
            createdAt: 0,
            durationMinutes: 0,
            visitMinutes: 0,
            ceiling: 0.0,
            pinned: false,
            status: ShiftManifestStatus.draft
        )
    }
}
