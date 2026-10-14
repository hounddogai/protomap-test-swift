import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary adjustment is in its life cycle.
    enum FormularyAdjustmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A formulary adjustment. Its code is unique within a tenant.
    final class FormularyAdjustment {
        var code: String
        var label: String
        var payer: String
        var endsAt: Int
        var specialty: String
        var diagnosisCode: String
        var visible: Bool
        var startsAt: Int
        var locale: String
        var batchSize: Int
        var status: FormularyAdjustmentStatus

        init(code: String, label: String, payer: String, endsAt: Int, specialty: String, diagnosisCode: String, visible: Bool, startsAt: Int, locale: String, batchSize: Int, status: FormularyAdjustmentStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.endsAt = endsAt
            self.specialty = specialty
            self.diagnosisCode = diagnosisCode
            self.visible = visible
            self.startsAt = startsAt
            self.locale = locale
            self.batchSize = batchSize
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

        func canMoveTo(_ next: FormularyAdjustmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == FormularyAdjustmentStatus.revoked || next == FormularyAdjustmentStatus.expired
            case .revoked:
                return next == FormularyAdjustmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedLoad() -> Double {
            return ((Double(endsAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> FormularyAdjustment {
            return FormularyAdjustment(
                code: code,
                label: label,
                payer: payer,
                endsAt: endsAt,
                specialty: specialty,
                diagnosisCode: diagnosisCode,
                visible: visible,
                startsAt: startsAt,
                locale: locale,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a formulary adjustment in status requested.
    static func newFormularyAdjustment(_ code: String, label: String) -> FormularyAdjustment {
        return FormularyAdjustment(
            code: code,
            label: label,
            payer: "",
            endsAt: 0,
            specialty: "",
            diagnosisCode: "",
            visible: false,
            startsAt: 0,
            locale: "",
            batchSize: 0,
            status: FormularyAdjustmentStatus.requested
        )
    }
}
