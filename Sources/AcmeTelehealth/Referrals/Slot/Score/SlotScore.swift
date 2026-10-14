import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot score is in its life cycle.
    enum SlotScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a slot score and its current status.
    final class SlotScore {
        var code: String
        var label: String
        var threshold: Double
        var locale: String
        var durationMinutes: Int
        var status: SlotScoreStatus

        init(code: String, label: String, threshold: Double, locale: String, durationMinutes: Int, status: SlotScoreStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.locale = locale
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: SlotScoreStatus) -> Bool {
            switch status {
            case .planned:
                return next == SlotScoreStatus.scheduled
            case .scheduled:
                return next == SlotScoreStatus.completed || next == SlotScoreStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == SlotScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveTotal() -> Double {
            return ((threshold - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SlotScore {
            return SlotScore(
                code: code,
                label: label,
                threshold: threshold,
                locale: locale,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a slot score in status planned.
    static func newSlotScore(_ code: String, label: String) -> SlotScore {
        return SlotScore(
            code: code,
            label: label,
            threshold: 0.0,
            locale: "",
            durationMinutes: 0,
            status: SlotScoreStatus.planned
        )
    }
}
