import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled handoff window is in its life cycle.
    enum ScheduledHandoffWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled handoff window as the handoff team keeps it.
    final class ScheduledHandoffWindow {
        var code: String
        var label: String
        var discount: Double
        var clinicianID: String
        var currency: String
        var dosageMg: Double
        var channel: String
        var status: ScheduledHandoffWindowStatus

        init(code: String, label: String, discount: Double, clinicianID: String, currency: String, dosageMg: Double, channel: String, status: ScheduledHandoffWindowStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.clinicianID = clinicianID
            self.currency = currency
            self.dosageMg = dosageMg
            self.channel = channel
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

        func canMoveTo(_ next: ScheduledHandoffWindowStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledHandoffWindowStatus.granted
            case .granted:
                return next == ScheduledHandoffWindowStatus.revoked || next == ScheduledHandoffWindowStatus.expired
            case .revoked:
                return next == ScheduledHandoffWindowStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledHandoffWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled handoff window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("scheduled handoff window") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((discount - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledHandoffWindow {
            return ScheduledHandoffWindow(
                code: code,
                label: label,
                discount: discount,
                clinicianID: clinicianID,
                currency: currency,
                dosageMg: dosageMg,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled handoff window in status requested.
    static func newScheduledHandoffWindow(_ code: String, label: String) -> ScheduledHandoffWindow {
        return ScheduledHandoffWindow(
            code: code,
            label: label,
            discount: 0.0,
            clinicianID: "",
            currency: "",
            dosageMg: 0.0,
            channel: "",
            status: ScheduledHandoffWindowStatus.requested
        )
    }
}
