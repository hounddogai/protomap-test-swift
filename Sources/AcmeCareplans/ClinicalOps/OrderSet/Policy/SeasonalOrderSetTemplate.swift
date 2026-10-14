import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal order set template is in its life cycle.
    enum SeasonalOrderSetTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One seasonal order set template, with what the planners need to act on it.
    final class SeasonalOrderSetTemplate {
        var code: String
        var label: String
        var visible: Bool
        var rate: Double
        var name: String
        var patientRef: String
        var status: SeasonalOrderSetTemplateStatus

        init(code: String, label: String, visible: Bool, rate: Double, name: String, patientRef: String, status: SeasonalOrderSetTemplateStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.rate = rate
            self.name = name
            self.patientRef = patientRef
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

        func canMoveTo(_ next: SeasonalOrderSetTemplateStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalOrderSetTemplateStatus.queued
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalOrderSetTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalOrderSetTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal order set template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> SeasonalOrderSetTemplate {
            return SeasonalOrderSetTemplate(
                code: code,
                label: label,
                visible: visible,
                rate: rate,
                name: name,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal order set template in status new.
    static func newSeasonalOrderSetTemplate(_ code: String, label: String) -> SeasonalOrderSetTemplate {
        return SeasonalOrderSetTemplate(
            code: code,
            label: label,
            visible: false,
            rate: 0.0,
            name: "",
            patientRef: "",
            status: SeasonalOrderSetTemplateStatus.new
        )
    }
}
