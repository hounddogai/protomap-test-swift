import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict assessment entry is in its life cycle.
    enum StrictAssessmentEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict assessment entry as the assessment team keeps it.
    final class StrictAssessmentEntry {
        var code: String
        var label: String
        var externalRef: String
        var diagnosisCode: String
        var category: String
        var source: String
        var amount: Double
        var threshold: Double
        var ward: String
        var graceDays: Int
        var copay: Double
        var status: StrictAssessmentEntryStatus

        init(code: String, label: String, externalRef: String, diagnosisCode: String, category: String, source: String, amount: Double, threshold: Double, ward: String, graceDays: Int, copay: Double, status: StrictAssessmentEntryStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.diagnosisCode = diagnosisCode
            self.category = category
            self.source = source
            self.amount = amount
            self.threshold = threshold
            self.ward = ward
            self.graceDays = graceDays
            self.copay = copay
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

        func canMoveTo(_ next: StrictAssessmentEntryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == StrictAssessmentEntryStatus.completed || next == StrictAssessmentEntryStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: StrictAssessmentEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict assessment entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return ((amount - threshold) * 100).rounded() / 100
        }

        func copyValue() -> StrictAssessmentEntry {
            return StrictAssessmentEntry(
                code: code,
                label: label,
                externalRef: externalRef,
                diagnosisCode: diagnosisCode,
                category: category,
                source: source,
                amount: amount,
                threshold: threshold,
                ward: ward,
                graceDays: graceDays,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a strict assessment entry in status planned.
    static func newStrictAssessmentEntry(_ code: String, label: String) -> StrictAssessmentEntry {
        return StrictAssessmentEntry(
            code: code,
            label: label,
            externalRef: "",
            diagnosisCode: "",
            category: "",
            source: "",
            amount: 0.0,
            threshold: 0.0,
            ward: "",
            graceDays: 0,
            copay: 0.0,
            status: StrictAssessmentEntryStatus.planned
        )
    }
}
