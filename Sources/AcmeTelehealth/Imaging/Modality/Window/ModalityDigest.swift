import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality digest is in its life cycle.
    enum ModalityDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A modality digest as the modality team keeps it.
    final class ModalityDigest {
        var code: String
        var name: String
        var copay: Double
        var unit: String
        var allergy: String
        var contactEmail: String
        var diagnosisCode: String
        var status: ModalityDigestStatus

        init(code: String, name: String, copay: Double, unit: String, allergy: String, contactEmail: String, diagnosisCode: String, status: ModalityDigestStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.unit = unit
            self.allergy = allergy
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ModalityDigestStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ModalityDigestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> ModalityDigest {
            return ModalityDigest(
                code: code,
                name: name,
                copay: copay,
                unit: unit,
                allergy: allergy,
                contactEmail: contactEmail,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a modality digest in status proposed.
    static func newModalityDigest(_ code: String, name: String) -> ModalityDigest {
        return ModalityDigest(
            code: code,
            name: name,
            copay: 0.0,
            unit: "",
            allergy: "",
            contactEmail: "",
            diagnosisCode: "",
            status: ModalityDigestStatus.proposed
        )
    }
}
