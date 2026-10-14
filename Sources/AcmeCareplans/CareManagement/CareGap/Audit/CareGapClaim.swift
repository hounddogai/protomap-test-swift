import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap claim is in its life cycle.
    enum CareGapClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A care gap claim as the care gap team keeps it.
    final class CareGapClaim {
        var code: String
        var name: String
        var ceiling: Double
        var patientRef: String
        var facility: String
        var durationMinutes: Int
        var status: CareGapClaimStatus

        init(code: String, name: String, ceiling: Double, patientRef: String, facility: String, durationMinutes: Int, status: CareGapClaimStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.patientRef = patientRef
            self.facility = facility
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapClaimStatus) -> Bool {
            switch status {
            case .created:
                return next == CareGapClaimStatus.validated || next == CareGapClaimStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == CareGapClaimStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care gap claim") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(durationMinutes) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> CareGapClaim {
            return CareGapClaim(
                code: code,
                name: name,
                ceiling: ceiling,
                patientRef: patientRef,
                facility: facility,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a care gap claim in status created.
    static func newCareGapClaim(_ code: String, name: String) -> CareGapClaim {
        return CareGapClaim(
            code: code,
            name: name,
            ceiling: 0.0,
            patientRef: "",
            facility: "",
            durationMinutes: 0,
            status: CareGapClaimStatus.created
        )
    }
}
