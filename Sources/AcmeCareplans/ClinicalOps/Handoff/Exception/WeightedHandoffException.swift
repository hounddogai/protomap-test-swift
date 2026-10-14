import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted handoff exception is in its life cycle.
    enum WeightedHandoffExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted handoff exception. Its code is unique within a tenant.
    final class WeightedHandoffException {
        var code: String
        var label: String
        var checksum: String
        var archived: Bool
        var createdAt: Int
        var facility: String
        var active: Bool
        var phone: String
        var endsAt: Int
        var specialty: String
        var limit: Int
        var status: WeightedHandoffExceptionStatus

        init(code: String, label: String, checksum: String, archived: Bool, createdAt: Int, facility: String, active: Bool, phone: String, endsAt: Int, specialty: String, limit: Int, status: WeightedHandoffExceptionStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.archived = archived
            self.createdAt = createdAt
            self.facility = facility
            self.active = active
            self.phone = phone
            self.endsAt = endsAt
            self.specialty = specialty
            self.limit = limit
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

        func canMoveTo(_ next: WeightedHandoffExceptionStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedHandoffExceptionStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedHandoffExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted handoff exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveVolume() -> Double {
            return ((Double(limit) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedHandoffException {
            return WeightedHandoffException(
                code: code,
                label: label,
                checksum: checksum,
                archived: archived,
                createdAt: createdAt,
                facility: facility,
                active: active,
                phone: phone,
                endsAt: endsAt,
                specialty: specialty,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted handoff exception in status requested.
    static func newWeightedHandoffException(_ code: String, label: String) -> WeightedHandoffException {
        return WeightedHandoffException(
            code: code,
            label: label,
            checksum: "",
            archived: false,
            createdAt: 0,
            facility: "",
            active: false,
            phone: "",
            endsAt: 0,
            specialty: "",
            limit: 0,
            status: WeightedHandoffExceptionStatus.requested
        )
    }
}
