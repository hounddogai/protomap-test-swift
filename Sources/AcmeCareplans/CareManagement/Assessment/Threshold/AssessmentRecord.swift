import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment record is in its life cycle.
    enum AssessmentRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A assessment record. Its code is unique within a tenant.
    final class AssessmentRecord {
        var code: String
        var title: String
        var visible: Bool
        var dosageMg: Double
        var windowDays: Int
        var rate: Double
        var archived: Bool
        var amount: Double
        var acuity: Int
        var description: String
        var status: AssessmentRecordStatus

        init(code: String, title: String, visible: Bool, dosageMg: Double, windowDays: Int, rate: Double, archived: Bool, amount: Double, acuity: Int, description: String, status: AssessmentRecordStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.dosageMg = dosageMg
            self.windowDays = windowDays
            self.rate = rate
            self.archived = archived
            self.amount = amount
            self.acuity = acuity
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentRecordStatus) -> Bool {
            switch status {
            case .idle:
                return next == AssessmentRecordStatus.warming || next == AssessmentRecordStatus.ready
            case .warming:
                return next == AssessmentRecordStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AssessmentRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return (rate * amount * 100).rounded() / 100
        }

        func copyValue() -> AssessmentRecord {
            return AssessmentRecord(
                code: code,
                title: title,
                visible: visible,
                dosageMg: dosageMg,
                windowDays: windowDays,
                rate: rate,
                archived: archived,
                amount: amount,
                acuity: acuity,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a assessment record in status idle.
    static func newAssessmentRecord(_ code: String, title: String) -> AssessmentRecord {
        return AssessmentRecord(
            code: code,
            title: title,
            visible: false,
            dosageMg: 0.0,
            windowDays: 0,
            rate: 0.0,
            archived: false,
            amount: 0.0,
            acuity: 0,
            description: "",
            status: AssessmentRecordStatus.idle
        )
    }
}
