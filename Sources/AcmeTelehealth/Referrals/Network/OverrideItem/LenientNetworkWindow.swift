import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient network window is in its life cycle.
    enum LenientNetworkWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a lenient network window and its current status.
    final class LenientNetworkWindow {
        var code: String
        var title: String
        var unit: String
        var approved: Bool
        var threshold: Double
        var pinned: Bool
        var name: String
        var attempts: Int
        var minimum: Double
        var status: LenientNetworkWindowStatus

        init(code: String, title: String, unit: String, approved: Bool, threshold: Double, pinned: Bool, name: String, attempts: Int, minimum: Double, status: LenientNetworkWindowStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.approved = approved
            self.threshold = threshold
            self.pinned = pinned
            self.name = name
            self.attempts = attempts
            self.minimum = minimum
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

        func canMoveTo(_ next: LenientNetworkWindowStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LenientNetworkWindowStatus.inProgress
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LenientNetworkWindowStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientNetworkWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient network window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return ((Double(attempts) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> LenientNetworkWindow {
            return LenientNetworkWindow(
                code: code,
                title: title,
                unit: unit,
                approved: approved,
                threshold: threshold,
                pinned: pinned,
                name: name,
                attempts: attempts,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient network window in status planned.
    static func newLenientNetworkWindow(_ code: String, title: String) -> LenientNetworkWindow {
        return LenientNetworkWindow(
            code: code,
            title: title,
            unit: "",
            approved: false,
            threshold: 0.0,
            pinned: false,
            name: "",
            attempts: 0,
            minimum: 0.0,
            status: LenientNetworkWindowStatus.planned
        )
    }
}
