import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling formulary segment is in its life cycle.
    enum RollingFormularySegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a rolling formulary segment and its current status.
    final class RollingFormularySegment {
        var code: String
        var label: String
        var checksum: String
        var expiresAt: Int
        var visitMinutes: Int
        var startsAt: Int
        var specialty: String
        var updatedAt: Int
        var version: Int
        var retries: Int
        var status: RollingFormularySegmentStatus

        init(code: String, label: String, checksum: String, expiresAt: Int, visitMinutes: Int, startsAt: Int, specialty: String, updatedAt: Int, version: Int, retries: Int, status: RollingFormularySegmentStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.expiresAt = expiresAt
            self.visitMinutes = visitMinutes
            self.startsAt = startsAt
            self.specialty = specialty
            self.updatedAt = updatedAt
            self.version = version
            self.retries = retries
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

        func canMoveTo(_ next: RollingFormularySegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingFormularySegmentStatus.retired
            case .validated:
                return next == RollingFormularySegmentStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingFormularySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling formulary segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return (Double(updatedAt) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RollingFormularySegment {
            return RollingFormularySegment(
                code: code,
                label: label,
                checksum: checksum,
                expiresAt: expiresAt,
                visitMinutes: visitMinutes,
                startsAt: startsAt,
                specialty: specialty,
                updatedAt: updatedAt,
                version: version,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling formulary segment in status created.
    static func newRollingFormularySegment(_ code: String, label: String) -> RollingFormularySegment {
        return RollingFormularySegment(
            code: code,
            label: label,
            checksum: "",
            expiresAt: 0,
            visitMinutes: 0,
            startsAt: 0,
            specialty: "",
            updatedAt: 0,
            version: 0,
            retries: 0,
            status: RollingFormularySegmentStatus.created
        )
    }
}
