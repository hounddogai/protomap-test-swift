import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional care protocol digest is in its life cycle.
    enum RegionalCareProtocolDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional care protocol digest as the care protocol team keeps it.
    final class RegionalCareProtocolDigest {
        var code: String
        var name: String
        var archived: Bool
        var ward: String
        var diagnosisCode: String
        var updatedAt: Int
        var patientRef: String
        var ratio: Double
        var endsAt: Int
        var status: RegionalCareProtocolDigestStatus

        init(code: String, name: String, archived: Bool, ward: String, diagnosisCode: String, updatedAt: Int, patientRef: String, ratio: Double, endsAt: Int, status: RegionalCareProtocolDigestStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.updatedAt = updatedAt
            self.patientRef = patientRef
            self.ratio = ratio
            self.endsAt = endsAt
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

        func canMoveTo(_ next: RegionalCareProtocolDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalCareProtocolDigestStatus.rejected
            case .approved:
                return next == RegionalCareProtocolDigestStatus.rejected || next == RegionalCareProtocolDigestStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RegionalCareProtocolDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care protocol digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return (Double(endsAt) * ratio * 100).rounded() / 100
        }

        func copyValue() -> RegionalCareProtocolDigest {
            return RegionalCareProtocolDigest(
                code: code,
                name: name,
                archived: archived,
                ward: ward,
                diagnosisCode: diagnosisCode,
                updatedAt: updatedAt,
                patientRef: patientRef,
                ratio: ratio,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional care protocol digest in status proposed.
    static func newRegionalCareProtocolDigest(_ code: String, name: String) -> RegionalCareProtocolDigest {
        return RegionalCareProtocolDigest(
            code: code,
            name: name,
            archived: false,
            ward: "",
            diagnosisCode: "",
            updatedAt: 0,
            patientRef: "",
            ratio: 0.0,
            endsAt: 0,
            status: RegionalCareProtocolDigestStatus.proposed
        )
    }
}
