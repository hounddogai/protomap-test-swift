import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled alert template is in its life cycle.
    enum ScheduledAlertTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled alert template as the alert team keeps it.
    final class ScheduledAlertTemplate {
        var code: String
        var title: String
        var facility: String
        var active: Bool
        var margin: Double
        var endsAt: Int
        var label: String
        var diagnosisCode: String
        var refills: Int
        var floorValue: Double
        var status: ScheduledAlertTemplateStatus

        init(code: String, title: String, facility: String, active: Bool, margin: Double, endsAt: Int, label: String, diagnosisCode: String, refills: Int, floorValue: Double, status: ScheduledAlertTemplateStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.active = active
            self.margin = margin
            self.endsAt = endsAt
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.refills = refills
            self.floorValue = floorValue
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

        func canMoveTo(_ next: ScheduledAlertTemplateStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledAlertTemplateStatus.queued || next == ScheduledAlertTemplateStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledAlertTemplateStatus.done || next == ScheduledAlertTemplateStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledAlertTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled alert template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("scheduled alert template") \(code)"
        }

        func weightedVolume() -> Double {
            return (Double(endsAt) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAlertTemplate {
            return ScheduledAlertTemplate(
                code: code,
                title: title,
                facility: facility,
                active: active,
                margin: margin,
                endsAt: endsAt,
                label: label,
                diagnosisCode: diagnosisCode,
                refills: refills,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a scheduled alert template in status new.
    static func newScheduledAlertTemplate(_ code: String, title: String) -> ScheduledAlertTemplate {
        return ScheduledAlertTemplate(
            code: code,
            title: title,
            facility: "",
            active: false,
            margin: 0.0,
            endsAt: 0,
            label: "",
            diagnosisCode: "",
            refills: 0,
            floorValue: 0.0,
            status: ScheduledAlertTemplateStatus.new
        )
    }
}
