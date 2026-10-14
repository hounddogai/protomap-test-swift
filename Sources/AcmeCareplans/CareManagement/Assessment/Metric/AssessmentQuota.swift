import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment quota is in its life cycle.
    enum AssessmentQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a assessment quota and its current status.
    final class AssessmentQuota {
        var code: String
        var name: String
        var active: Bool
        var createdAt: Int
        var region: String
        var attributes: [String: String]
        var weight: Double
        var durationMinutes: Int
        var ward: String
        var status: AssessmentQuotaStatus

        init(code: String, name: String, active: Bool, createdAt: Int, region: String, attributes: [String: String], weight: Double, durationMinutes: Int, ward: String, status: AssessmentQuotaStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.createdAt = createdAt
            self.region = region
            self.attributes = attributes
            self.weight = weight
            self.durationMinutes = durationMinutes
            self.ward = ward
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

        func canMoveTo(_ next: AssessmentQuotaStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AssessmentQuotaStatus.revoked || next == AssessmentQuotaStatus.expired
            case .revoked:
                return next == AssessmentQuotaStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedValue() -> Double {
            return ((weight - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentQuota {
            return AssessmentQuota(
                code: code,
                name: name,
                active: active,
                createdAt: createdAt,
                region: region,
                attributes: attributes,
                weight: weight,
                durationMinutes: durationMinutes,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a assessment quota in status requested.
    static func newAssessmentQuota(_ code: String, name: String) -> AssessmentQuota {
        return AssessmentQuota(
            code: code,
            name: name,
            active: false,
            createdAt: 0,
            region: "",
            attributes: [:],
            weight: 0.0,
            durationMinutes: 0,
            ward: "",
            status: AssessmentQuotaStatus.requested
        )
    }
}
