import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel variance is in its life cycle.
    enum PanelVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One panel variance, with what the planners need to act on it.
    final class PanelVariance {
        var code: String
        var label: String
        var tags: [String]
        var graceDays: Int
        var payer: String
        var status: PanelVarianceStatus

        init(code: String, label: String, tags: [String], graceDays: Int, payer: String, status: PanelVarianceStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.graceDays = graceDays
            self.payer = payer
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

        func canMoveTo(_ next: PanelVarianceStatus) -> Bool {
            switch status {
            case .planned:
                return next == PanelVarianceStatus.scheduled || next == PanelVarianceStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
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
                return next == PanelVarianceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("panel variance") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> PanelVariance {
            return PanelVariance(
                code: code,
                label: label,
                tags: tags,
                graceDays: graceDays,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel variance in status planned.
    static func newPanelVariance(_ code: String, label: String) -> PanelVariance {
        return PanelVariance(
            code: code,
            label: label,
            tags: [],
            graceDays: 0,
            payer: "",
            status: PanelVarianceStatus.planned
        )
    }
}
