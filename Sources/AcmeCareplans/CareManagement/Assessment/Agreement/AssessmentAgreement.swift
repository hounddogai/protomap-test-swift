import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment agreement is in its life cycle.
    enum AssessmentAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A assessment agreement as the assessment team keeps it.
    final class AssessmentAgreement {
        var code: String
        var label: String
        var version: Int
        var summary: String
        var batchSize: Int
        var ratio: Double
        var windowDays: Int
        var threshold: Double
        var name: String
        var patientRef: String
        var status: AssessmentAgreementStatus

        init(code: String, label: String, version: Int, summary: String, batchSize: Int, ratio: Double, windowDays: Int, threshold: Double, name: String, patientRef: String, status: AssessmentAgreementStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.summary = summary
            self.batchSize = batchSize
            self.ratio = ratio
            self.windowDays = windowDays
            self.threshold = threshold
            self.name = name
            self.patientRef = patientRef
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

        func canMoveTo(_ next: AssessmentAgreementStatus) -> Bool {
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
                return next == AssessmentAgreementStatus.suspended
            case .active:
                return next == AssessmentAgreementStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: AssessmentAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(version) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentAgreement {
            return AssessmentAgreement(
                code: code,
                label: label,
                version: version,
                summary: summary,
                batchSize: batchSize,
                ratio: ratio,
                windowDays: windowDays,
                threshold: threshold,
                name: name,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a assessment agreement in status draft.
    static func newAssessmentAgreement(_ code: String, label: String) -> AssessmentAgreement {
        return AssessmentAgreement(
            code: code,
            label: label,
            version: 0,
            summary: "",
            batchSize: 0,
            ratio: 0.0,
            windowDays: 0,
            threshold: 0.0,
            name: "",
            patientRef: "",
            status: AssessmentAgreementStatus.draft
        )
    }
}
