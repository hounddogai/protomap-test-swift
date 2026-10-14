import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment profile is in its life cycle.
    enum AssessmentProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A assessment profile as the assessment team keeps it.
    final class AssessmentProfile {
        var code: String
        var name: String
        var createdAt: Int
        var visible: Bool
        var channel: String
        var procedureCode: String
        var segment: String
        var phone: String
        var diagnosisCode: String
        var archived: Bool
        var status: AssessmentProfileStatus

        init(code: String, name: String, createdAt: Int, visible: Bool, channel: String, procedureCode: String, segment: String, phone: String, diagnosisCode: String, archived: Bool, status: AssessmentProfileStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.visible = visible
            self.channel = channel
            self.procedureCode = procedureCode
            self.segment = segment
            self.phone = phone
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentProfileStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AssessmentProfileStatus.published || next == AssessmentProfileStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AssessmentProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> AssessmentProfile {
            return AssessmentProfile(
                code: code,
                name: name,
                createdAt: createdAt,
                visible: visible,
                channel: channel,
                procedureCode: procedureCode,
                segment: segment,
                phone: phone,
                diagnosisCode: diagnosisCode,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a assessment profile in status created.
    static func newAssessmentProfile(_ code: String, name: String) -> AssessmentProfile {
        return AssessmentProfile(
            code: code,
            name: name,
            createdAt: 0,
            visible: false,
            channel: "",
            procedureCode: "",
            segment: "",
            phone: "",
            diagnosisCode: "",
            archived: false,
            status: AssessmentProfileStatus.created
        )
    }
}
