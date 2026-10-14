import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy language template is in its life cycle.
    enum LegacyLanguageTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a legacy language template and its current status.
    final class LegacyLanguageTemplate {
        var code: String
        var title: String
        var refills: Int
        var ownerID: String
        var locale: String
        var patientRef: String
        var source: String
        var ceiling: Double
        var description: String
        var diagnosisCode: String
        var status: LegacyLanguageTemplateStatus

        init(code: String, title: String, refills: Int, ownerID: String, locale: String, patientRef: String, source: String, ceiling: Double, description: String, diagnosisCode: String, status: LegacyLanguageTemplateStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.ownerID = ownerID
            self.locale = locale
            self.patientRef = patientRef
            self.source = source
            self.ceiling = ceiling
            self.description = description
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: LegacyLanguageTemplateStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyLanguageTemplateStatus.queued
            case .queued:
                return next == LegacyLanguageTemplateStatus.running || next == LegacyLanguageTemplateStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LegacyLanguageTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy language template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netExposure() -> Double {
            return ((Double(refills) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> LegacyLanguageTemplate {
            return LegacyLanguageTemplate(
                code: code,
                title: title,
                refills: refills,
                ownerID: ownerID,
                locale: locale,
                patientRef: patientRef,
                source: source,
                ceiling: ceiling,
                description: description,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy language template in status new.
    static func newLegacyLanguageTemplate(_ code: String, title: String) -> LegacyLanguageTemplate {
        return LegacyLanguageTemplate(
            code: code,
            title: title,
            refills: 0,
            ownerID: "",
            locale: "",
            patientRef: "",
            source: "",
            ceiling: 0.0,
            description: "",
            diagnosisCode: "",
            status: LegacyLanguageTemplateStatus.new
        )
    }
}
