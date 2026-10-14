import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient rounding template is in its life cycle.
    enum LenientRoundingTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient rounding template as the rounding team keeps it.
    final class LenientRoundingTemplate {
        var code: String
        var name: String
        var attempts: Int
        var acuity: Int
        var expiresAt: Int
        var facility: String
        var approved: Bool
        var diagnosisCode: String
        var status: LenientRoundingTemplateStatus

        init(code: String, name: String, attempts: Int, acuity: Int, expiresAt: Int, facility: String, approved: Bool, diagnosisCode: String, status: LenientRoundingTemplateStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.acuity = acuity
            self.expiresAt = expiresAt
            self.facility = facility
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientRoundingTemplateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LenientRoundingTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient rounding template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient rounding template") \(code)"
        }

        func effectiveLoad() -> Double {
            return (Double(acuity) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> LenientRoundingTemplate {
            return LenientRoundingTemplate(
                code: code,
                name: name,
                attempts: attempts,
                acuity: acuity,
                expiresAt: expiresAt,
                facility: facility,
                approved: approved,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a lenient rounding template in status requested.
    static func newLenientRoundingTemplate(_ code: String, name: String) -> LenientRoundingTemplate {
        return LenientRoundingTemplate(
            code: code,
            name: name,
            attempts: 0,
            acuity: 0,
            expiresAt: 0,
            facility: "",
            approved: false,
            diagnosisCode: "",
            status: LenientRoundingTemplateStatus.requested
        )
    }
}
