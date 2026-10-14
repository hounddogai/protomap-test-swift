import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap profile is in its life cycle.
    enum CareGapProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A care gap profile. Its code is unique within a tenant.
    final class CareGapProfile {
        var code: String
        var name: String
        var graceDays: Int
        var active: Bool
        var revision: Int
        var endsAt: Int
        var bed: String
        var copay: Double
        var specialty: String
        var status: CareGapProfileStatus

        init(code: String, name: String, graceDays: Int, active: Bool, revision: Int, endsAt: Int, bed: String, copay: Double, specialty: String, status: CareGapProfileStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.active = active
            self.revision = revision
            self.endsAt = endsAt
            self.bed = bed
            self.copay = copay
            self.specialty = specialty
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

        func canMoveTo(_ next: CareGapProfileStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CareGapProfileStatus.rejected || next == CareGapProfileStatus.withdrawn
            case .approved:
                return next == CareGapProfileStatus.rejected || next == CareGapProfileStatus.withdrawn
            case .rejected:
                return next == CareGapProfileStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveExposure() -> Double {
            return ((Double(endsAt) - copay) * 100).rounded() / 100
        }

        func copyValue() -> CareGapProfile {
            return CareGapProfile(
                code: code,
                name: name,
                graceDays: graceDays,
                active: active,
                revision: revision,
                endsAt: endsAt,
                bed: bed,
                copay: copay,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care gap profile in status proposed.
    static func newCareGapProfile(_ code: String, name: String) -> CareGapProfile {
        return CareGapProfile(
            code: code,
            name: name,
            graceDays: 0,
            active: false,
            revision: 0,
            endsAt: 0,
            bed: "",
            copay: 0.0,
            specialty: "",
            status: CareGapProfileStatus.proposed
        )
    }
}
