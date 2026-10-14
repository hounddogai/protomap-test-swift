import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal closure window is in its life cycle.
    enum SeasonalClosureWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal closure window as the closure team keeps it.
    final class SeasonalClosureWindow {
        var code: String
        var label: String
        var name: String
        var clinicianID: String
        var ceiling: Double
        var status: SeasonalClosureWindowStatus

        init(code: String, label: String, name: String, clinicianID: String, ceiling: Double, status: SeasonalClosureWindowStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.clinicianID = clinicianID
            self.ceiling = ceiling
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

        func canMoveTo(_ next: SeasonalClosureWindowStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalClosureWindowStatus.queued
            case .queued:
                return next == SeasonalClosureWindowStatus.done || next == SeasonalClosureWindowStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalClosureWindowStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalClosureWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal closure window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal closure window") \(code)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> SeasonalClosureWindow {
            return SeasonalClosureWindow(
                code: code,
                label: label,
                name: name,
                clinicianID: clinicianID,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal closure window in status new.
    static func newSeasonalClosureWindow(_ code: String, label: String) -> SeasonalClosureWindow {
        return SeasonalClosureWindow(
            code: code,
            label: label,
            name: "",
            clinicianID: "",
            ceiling: 0.0,
            status: SeasonalClosureWindowStatus.new
        )
    }
}
