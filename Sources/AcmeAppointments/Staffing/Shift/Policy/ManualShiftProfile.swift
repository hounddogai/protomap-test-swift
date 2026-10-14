import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual shift profile is in its life cycle.
    enum ManualShiftProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual shift profile as the shift team keeps it.
    final class ManualShiftProfile {
        var code: String
        var label: String
        var retries: Int
        var externalRef: String
        var discount: Double
        var status: ManualShiftProfileStatus

        init(code: String, label: String, retries: Int, externalRef: String, discount: Double, status: ManualShiftProfileStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.externalRef = externalRef
            self.discount = discount
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

        func canMoveTo(_ next: ManualShiftProfileStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualShiftProfileStatus.withdrawn
            case .approved:
                return next == ManualShiftProfileStatus.rejected || next == ManualShiftProfileStatus.withdrawn
            case .rejected:
                return next == ManualShiftProfileStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualShiftProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual shift profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual shift profile") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(retries) - discount) * 100).rounded() / 100
        }

        func copyValue() -> ManualShiftProfile {
            return ManualShiftProfile(
                code: code,
                label: label,
                retries: retries,
                externalRef: externalRef,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual shift profile in status proposed.
    static func newManualShiftProfile(_ code: String, label: String) -> ManualShiftProfile {
        return ManualShiftProfile(
            code: code,
            label: label,
            retries: 0,
            externalRef: "",
            discount: 0.0,
            status: ManualShiftProfileStatus.proposed
        )
    }
}
