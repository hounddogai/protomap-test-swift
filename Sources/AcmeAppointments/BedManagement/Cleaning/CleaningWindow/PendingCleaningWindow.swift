import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending cleaning window is in its life cycle.
    enum PendingCleaningWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending cleaning window. Its code is unique within a tenant.
    final class PendingCleaningWindow {
        var code: String
        var label: String
        var minimum: Double
        var active: Bool
        var reviewer: String
        var ratio: Double
        var durationMinutes: Int
        var expiresAt: Int
        var maximum: Double
        var status: PendingCleaningWindowStatus

        init(code: String, label: String, minimum: Double, active: Bool, reviewer: String, ratio: Double, durationMinutes: Int, expiresAt: Int, maximum: Double, status: PendingCleaningWindowStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.active = active
            self.reviewer = reviewer
            self.ratio = ratio
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.maximum = maximum
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

        func canMoveTo(_ next: PendingCleaningWindowStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingCleaningWindowStatus.resolved || next == PendingCleaningWindowStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PendingCleaningWindowStatus.reopened || next == PendingCleaningWindowStatus.archived
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

        func moveTo(_ next: PendingCleaningWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending cleaning window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("pending cleaning window") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(expiresAt) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> PendingCleaningWindow {
            return PendingCleaningWindow(
                code: code,
                label: label,
                minimum: minimum,
                active: active,
                reviewer: reviewer,
                ratio: ratio,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending cleaning window in status open.
    static func newPendingCleaningWindow(_ code: String, label: String) -> PendingCleaningWindow {
        return PendingCleaningWindow(
            code: code,
            label: label,
            minimum: 0.0,
            active: false,
            reviewer: "",
            ratio: 0.0,
            durationMinutes: 0,
            expiresAt: 0,
            maximum: 0.0,
            status: PendingCleaningWindowStatus.`open`
        )
    }
}
