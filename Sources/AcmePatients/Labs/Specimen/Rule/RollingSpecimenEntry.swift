import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling specimen entry is in its life cycle.
    enum RollingSpecimenEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling specimen entry as the specimen team keeps it.
    final class RollingSpecimenEntry {
        var code: String
        var title: String
        var version: Int
        var minimum: Double
        var limit: Int
        var phone: String
        var specialty: String
        var facility: String
        var revision: Int
        var windowDays: Int
        var status: RollingSpecimenEntryStatus

        init(code: String, title: String, version: Int, minimum: Double, limit: Int, phone: String, specialty: String, facility: String, revision: Int, windowDays: Int, status: RollingSpecimenEntryStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.minimum = minimum
            self.limit = limit
            self.phone = phone
            self.specialty = specialty
            self.facility = facility
            self.revision = revision
            self.windowDays = windowDays
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

        func canMoveTo(_ next: RollingSpecimenEntryStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingSpecimenEntryStatus.revoked || next == RollingSpecimenEntryStatus.expired
            case .granted:
                return next == RollingSpecimenEntryStatus.revoked
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

        func moveTo(_ next: RollingSpecimenEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling specimen entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return (Double(revision) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> RollingSpecimenEntry {
            return RollingSpecimenEntry(
                code: code,
                title: title,
                version: version,
                minimum: minimum,
                limit: limit,
                phone: phone,
                specialty: specialty,
                facility: facility,
                revision: revision,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rolling specimen entry in status requested.
    static func newRollingSpecimenEntry(_ code: String, title: String) -> RollingSpecimenEntry {
        return RollingSpecimenEntry(
            code: code,
            title: title,
            version: 0,
            minimum: 0.0,
            limit: 0,
            phone: "",
            specialty: "",
            facility: "",
            revision: 0,
            windowDays: 0,
            status: RollingSpecimenEntryStatus.requested
        )
    }
}
