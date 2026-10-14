import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim reservation is in its life cycle.
    enum ClaimReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A claim reservation. Its code is unique within a tenant.
    final class ClaimReservation {
        var code: String
        var label: String
        var phone: String
        var visible: Bool
        var threshold: Double
        var patientRef: String
        var status: ClaimReservationStatus

        init(code: String, label: String, phone: String, visible: Bool, threshold: Double, patientRef: String, status: ClaimReservationStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.visible = visible
            self.threshold = threshold
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimReservationStatus) -> Bool {
            switch status {
            case .draft:
                return next == ClaimReservationStatus.pending || next == ClaimReservationStatus.active
            case .pending:
                return next == ClaimReservationStatus.active
            case .active:
                return next == ClaimReservationStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ClaimReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> ClaimReservation {
            return ClaimReservation(
                code: code,
                label: label,
                phone: phone,
                visible: visible,
                threshold: threshold,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a claim reservation in status draft.
    static func newClaimReservation(_ code: String, label: String) -> ClaimReservation {
        return ClaimReservation(
            code: code,
            label: label,
            phone: "",
            visible: false,
            threshold: 0.0,
            patientRef: "",
            status: ClaimReservationStatus.draft
        )
    }
}
