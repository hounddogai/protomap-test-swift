import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy assessment policy is in its life cycle.
    enum LegacyAssessmentPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy assessment policy. Its code is unique within a tenant.
    final class LegacyAssessmentPolicy {
        var code: String
        var title: String
        var locale: String
        var unit: String
        var ward: String
        var dosageMg: Double
        var category: String
        var specialty: String
        var status: LegacyAssessmentPolicyStatus

        init(code: String, title: String, locale: String, unit: String, ward: String, dosageMg: Double, category: String, specialty: String, status: LegacyAssessmentPolicyStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.unit = unit
            self.ward = ward
            self.dosageMg = dosageMg
            self.category = category
            self.specialty = specialty
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

        func canMoveTo(_ next: LegacyAssessmentPolicyStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LegacyAssessmentPolicyStatus.closed
            case .active:
                return next == LegacyAssessmentPolicyStatus.suspended || next == LegacyAssessmentPolicyStatus.closed
            case .suspended:
                return next == LegacyAssessmentPolicyStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAssessmentPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy assessment policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy assessment policy") \(code)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> LegacyAssessmentPolicy {
            return LegacyAssessmentPolicy(
                code: code,
                title: title,
                locale: locale,
                unit: unit,
                ward: ward,
                dosageMg: dosageMg,
                category: category,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy assessment policy in status draft.
    static func newLegacyAssessmentPolicy(_ code: String, title: String) -> LegacyAssessmentPolicy {
        return LegacyAssessmentPolicy(
            code: code,
            title: title,
            locale: "",
            unit: "",
            ward: "",
            dosageMg: 0.0,
            category: "",
            specialty: "",
            status: LegacyAssessmentPolicyStatus.draft
        )
    }
}
