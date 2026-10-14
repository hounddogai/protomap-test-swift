import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel forecast is in its life cycle.
    enum PanelForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One panel forecast, with what the planners need to act on it.
    final class PanelForecast {
        var code: String
        var label: String
        var attempts: Int
        var threshold: Double
        var specialty: String
        var visitMinutes: Int
        var status: PanelForecastStatus

        init(code: String, label: String, attempts: Int, threshold: Double, specialty: String, visitMinutes: Int, status: PanelForecastStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.threshold = threshold
            self.specialty = specialty
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: PanelForecastStatus) -> Bool {
            switch status {
            case .planned:
                return next == PanelForecastStatus.inProgress || next == PanelForecastStatus.cancelled
            case .scheduled:
                return next == PanelForecastStatus.cancelled
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

        func moveTo(_ next: PanelForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedVolume() -> Double {
            return ((threshold - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PanelForecast {
            return PanelForecast(
                code: code,
                label: label,
                attempts: attempts,
                threshold: threshold,
                specialty: specialty,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel forecast in status planned.
    static func newPanelForecast(_ code: String, label: String) -> PanelForecast {
        return PanelForecast(
            code: code,
            label: label,
            attempts: 0,
            threshold: 0.0,
            specialty: "",
            visitMinutes: 0,
            status: PanelForecastStatus.planned
        )
    }
}
