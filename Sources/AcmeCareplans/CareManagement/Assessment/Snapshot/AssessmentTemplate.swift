import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment template is in its life cycle.
    enum AssessmentTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a assessment template and its current status.
    final class AssessmentTemplate {
        var code: String
        var name: String
        var payer: String
        var facility: String
        var externalRef: String
        var encounterID: String
        var limit: Int
        var label: String
        var ward: String
        var status: AssessmentTemplateStatus

        init(code: String, name: String, payer: String, facility: String, externalRef: String, encounterID: String, limit: Int, label: String, ward: String, status: AssessmentTemplateStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.facility = facility
            self.externalRef = externalRef
            self.encounterID = encounterID
            self.limit = limit
            self.label = label
            self.ward = ward
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

        func canMoveTo(_ next: AssessmentTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AssessmentTemplateStatus.draining || next == AssessmentTemplateStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AssessmentTemplateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> AssessmentTemplate {
            return AssessmentTemplate(
                code: code,
                name: name,
                payer: payer,
                facility: facility,
                externalRef: externalRef,
                encounterID: encounterID,
                limit: limit,
                label: label,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a assessment template in status idle.
    static func newAssessmentTemplate(_ code: String, name: String) -> AssessmentTemplate {
        return AssessmentTemplate(
            code: code,
            name: name,
            payer: "",
            facility: "",
            externalRef: "",
            encounterID: "",
            limit: 0,
            label: "",
            ward: "",
            status: AssessmentTemplateStatus.idle
        )
    }
}
