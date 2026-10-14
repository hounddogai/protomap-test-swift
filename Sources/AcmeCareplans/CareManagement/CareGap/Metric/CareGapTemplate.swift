import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap template is in its life cycle.
    enum CareGapTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a care gap template and its current status.
    final class CareGapTemplate {
        var code: String
        var label: String
        var patientRef: String
        var priority: Int
        var summary: String
        var ward: String
        var threshold: Double
        var locale: String
        var acuity: Int
        var status: CareGapTemplateStatus

        init(code: String, label: String, patientRef: String, priority: Int, summary: String, ward: String, threshold: Double, locale: String, acuity: Int, status: CareGapTemplateStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.priority = priority
            self.summary = summary
            self.ward = ward
            self.threshold = threshold
            self.locale = locale
            self.acuity = acuity
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

        func canMoveTo(_ next: CareGapTemplateStatus) -> Bool {
            switch status {
            case .draft:
                return next == CareGapTemplateStatus.closed
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CareGapTemplateStatus.closed
            case .suspended:
                return next == CareGapTemplateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("care gap template") \(code)"
        }

        func weightedLoad() -> Double {
            return (threshold * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> CareGapTemplate {
            return CareGapTemplate(
                code: code,
                label: label,
                patientRef: patientRef,
                priority: priority,
                summary: summary,
                ward: ward,
                threshold: threshold,
                locale: locale,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a care gap template in status draft.
    static func newCareGapTemplate(_ code: String, label: String) -> CareGapTemplate {
        return CareGapTemplate(
            code: code,
            label: label,
            patientRef: "",
            priority: 0,
            summary: "",
            ward: "",
            threshold: 0.0,
            locale: "",
            acuity: 0,
            status: CareGapTemplateStatus.draft
        )
    }
}
