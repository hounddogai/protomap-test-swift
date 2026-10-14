import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling task record is in its life cycle.
    enum RollingTaskRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One rolling task record, with what the planners need to act on it.
    final class RollingTaskRecord {
        var code: String
        var name: String
        var phone: String
        var weight: Double
        var source: String
        var ownerID: String
        var revision: Int
        var retries: Int
        var status: RollingTaskRecordStatus

        init(code: String, name: String, phone: String, weight: Double, source: String, ownerID: String, revision: Int, retries: Int, status: RollingTaskRecordStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.weight = weight
            self.source = source
            self.ownerID = ownerID
            self.revision = revision
            self.retries = retries
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

        func canMoveTo(_ next: RollingTaskRecordStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingTaskRecordStatus.revoked
            case .granted:
                return next == RollingTaskRecordStatus.revoked || next == RollingTaskRecordStatus.expired
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

        func moveTo(_ next: RollingTaskRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling task record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return ((Double(retries) - weight) * 100).rounded() / 100
        }

        func copyValue() -> RollingTaskRecord {
            return RollingTaskRecord(
                code: code,
                name: name,
                phone: phone,
                weight: weight,
                source: source,
                ownerID: ownerID,
                revision: revision,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling task record in status requested.
    static func newRollingTaskRecord(_ code: String, name: String) -> RollingTaskRecord {
        return RollingTaskRecord(
            code: code,
            name: name,
            phone: "",
            weight: 0.0,
            source: "",
            ownerID: "",
            revision: 0,
            retries: 0,
            status: RollingTaskRecordStatus.requested
        )
    }
}
