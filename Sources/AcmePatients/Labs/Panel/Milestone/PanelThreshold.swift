import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel threshold is in its life cycle.
    enum PanelThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a panel threshold and its current status.
    final class PanelThreshold {
        var code: String
        var label: String
        var ward: String
        var durationMinutes: Int
        var batchSize: Int
        var country: String
        var patientRef: String
        var attempts: Int
        var payer: String
        var specialty: String
        var status: PanelThresholdStatus

        init(code: String, label: String, ward: String, durationMinutes: Int, batchSize: Int, country: String, patientRef: String, attempts: Int, payer: String, specialty: String, status: PanelThresholdStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
            self.country = country
            self.patientRef = patientRef
            self.attempts = attempts
            self.payer = payer
            self.specialty = specialty
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

        func canMoveTo(_ next: PanelThresholdStatus) -> Bool {
            switch status {
            case .requested:
                return next == PanelThresholdStatus.granted || next == PanelThresholdStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PanelThresholdStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netVolume() -> Double {
            return ((Double(durationMinutes) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> PanelThreshold {
            return PanelThreshold(
                code: code,
                label: label,
                ward: ward,
                durationMinutes: durationMinutes,
                batchSize: batchSize,
                country: country,
                patientRef: patientRef,
                attempts: attempts,
                payer: payer,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a panel threshold in status requested.
    static func newPanelThreshold(_ code: String, label: String) -> PanelThreshold {
        return PanelThreshold(
            code: code,
            label: label,
            ward: "",
            durationMinutes: 0,
            batchSize: 0,
            country: "",
            patientRef: "",
            attempts: 0,
            payer: "",
            specialty: "",
            status: PanelThresholdStatus.requested
        )
    }
}
