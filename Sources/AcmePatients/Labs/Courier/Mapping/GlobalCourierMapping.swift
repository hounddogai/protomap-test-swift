import AcmePlatform
import Foundation

extension Labs {
    /// Where a global courier mapping is in its life cycle.
    enum GlobalCourierMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global courier mapping. Its code is unique within a tenant.
    final class GlobalCourierMapping {
        var code: String
        var title: String
        var active: Bool
        var expiresAt: Int
        var acuity: Int
        var clinicianID: String
        var margin: Double
        var payer: String
        var dosageMg: Double
        var tags: [String]
        var diagnosisCode: String
        var status: GlobalCourierMappingStatus

        init(code: String, title: String, active: Bool, expiresAt: Int, acuity: Int, clinicianID: String, margin: Double, payer: String, dosageMg: Double, tags: [String], diagnosisCode: String, status: GlobalCourierMappingStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.expiresAt = expiresAt
            self.acuity = acuity
            self.clinicianID = clinicianID
            self.margin = margin
            self.payer = payer
            self.dosageMg = dosageMg
            self.tags = tags
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: GlobalCourierMappingStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalCourierMappingStatus.scheduled || next == GlobalCourierMappingStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == GlobalCourierMappingStatus.completed || next == GlobalCourierMappingStatus.cancelled
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

        func moveTo(_ next: GlobalCourierMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global courier mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global courier mapping") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return (margin * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> GlobalCourierMapping {
            return GlobalCourierMapping(
                code: code,
                title: title,
                active: active,
                expiresAt: expiresAt,
                acuity: acuity,
                clinicianID: clinicianID,
                margin: margin,
                payer: payer,
                dosageMg: dosageMg,
                tags: tags,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global courier mapping in status planned.
    static func newGlobalCourierMapping(_ code: String, title: String) -> GlobalCourierMapping {
        return GlobalCourierMapping(
            code: code,
            title: title,
            active: false,
            expiresAt: 0,
            acuity: 0,
            clinicianID: "",
            margin: 0.0,
            payer: "",
            dosageMg: 0.0,
            tags: [],
            diagnosisCode: "",
            status: GlobalCourierMappingStatus.planned
        )
    }
}
