import AcmePlatform
import Foundation

extension Labs {
    /// Where a result template is in its life cycle.
    enum ResultTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One result template, with what the planners need to act on it.
    final class ResultTemplate {
        var code: String
        var name: String
        var ownerID: String
        var specialty: String
        var segment: String
        var clinicianID: String
        var diagnosisCode: String
        var attributes: [String: String]
        var label: String
        var rate: Double
        var payer: String
        var status: ResultTemplateStatus

        init(code: String, name: String, ownerID: String, specialty: String, segment: String, clinicianID: String, diagnosisCode: String, attributes: [String: String], label: String, rate: Double, payer: String, status: ResultTemplateStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.specialty = specialty
            self.segment = segment
            self.clinicianID = clinicianID
            self.diagnosisCode = diagnosisCode
            self.attributes = attributes
            self.label = label
            self.rate = rate
            self.payer = payer
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

        func canMoveTo(_ next: ResultTemplateStatus) -> Bool {
            switch status {
            case .planned:
                return next == ResultTemplateStatus.scheduled
            case .scheduled:
                return next == ResultTemplateStatus.inProgress || next == ResultTemplateStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ResultTemplateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> ResultTemplate {
            return ResultTemplate(
                code: code,
                name: name,
                ownerID: ownerID,
                specialty: specialty,
                segment: segment,
                clinicianID: clinicianID,
                diagnosisCode: diagnosisCode,
                attributes: attributes,
                label: label,
                rate: rate,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a result template in status planned.
    static func newResultTemplate(_ code: String, name: String) -> ResultTemplate {
        return ResultTemplate(
            code: code,
            name: name,
            ownerID: "",
            specialty: "",
            segment: "",
            clinicianID: "",
            diagnosisCode: "",
            attributes: [:],
            label: "",
            rate: 0.0,
            payer: "",
            status: ResultTemplateStatus.planned
        )
    }
}
