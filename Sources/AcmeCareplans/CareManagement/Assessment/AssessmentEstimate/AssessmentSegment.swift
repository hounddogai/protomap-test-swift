import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment segment is in its life cycle.
    enum AssessmentSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a assessment segment and its current status.
    final class AssessmentSegment {
        var code: String
        var label: String
        var maximum: Double
        var version: Int
        var visitMinutes: Int
        var revision: Int
        var currency: String
        var clinicianID: String
        var phone: String
        var archived: Bool
        var payer: String
        var status: AssessmentSegmentStatus

        init(code: String, label: String, maximum: Double, version: Int, visitMinutes: Int, revision: Int, currency: String, clinicianID: String, phone: String, archived: Bool, payer: String, status: AssessmentSegmentStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.version = version
            self.visitMinutes = visitMinutes
            self.revision = revision
            self.currency = currency
            self.clinicianID = clinicianID
            self.phone = phone
            self.archived = archived
            self.payer = payer
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

        func canMoveTo(_ next: AssessmentSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AssessmentSegmentStatus.closed
            case .active:
                return next == AssessmentSegmentStatus.closed
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

        func moveTo(_ next: AssessmentSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("assessment segment") \(code)"
        }

        func projectedValue() -> Double {
            return ((maximum + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentSegment {
            return AssessmentSegment(
                code: code,
                label: label,
                maximum: maximum,
                version: version,
                visitMinutes: visitMinutes,
                revision: revision,
                currency: currency,
                clinicianID: clinicianID,
                phone: phone,
                archived: archived,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a assessment segment in status draft.
    static func newAssessmentSegment(_ code: String, label: String) -> AssessmentSegment {
        return AssessmentSegment(
            code: code,
            label: label,
            maximum: 0.0,
            version: 0,
            visitMinutes: 0,
            revision: 0,
            currency: "",
            clinicianID: "",
            phone: "",
            archived: false,
            payer: "",
            status: AssessmentSegmentStatus.draft
        )
    }
}
