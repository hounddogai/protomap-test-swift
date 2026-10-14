import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan tier is in its life cycle.
    enum AcuityPlanTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A acuity plan tier. Its code is unique within a tenant.
    final class AcuityPlanTier {
        var code: String
        var name: String
        var country: String
        var ward: String
        var retries: Int
        var source: String
        var active: Bool
        var version: Int
        var pinned: Bool
        var limit: Int
        var status: AcuityPlanTierStatus

        init(code: String, name: String, country: String, ward: String, retries: Int, source: String, active: Bool, version: Int, pinned: Bool, limit: Int, status: AcuityPlanTierStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.ward = ward
            self.retries = retries
            self.source = source
            self.active = active
            self.version = version
            self.pinned = pinned
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AcuityPlanTierStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AcuityPlanTierStatus.reopened
            case .inReview:
                return next == AcuityPlanTierStatus.reopened
            case .resolved:
                return next == AcuityPlanTierStatus.reopened
            case .reopened:
                return next == AcuityPlanTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedTotal() -> Double {
            return ((Double(retries) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanTier {
            return AcuityPlanTier(
                code: code,
                name: name,
                country: country,
                ward: ward,
                retries: retries,
                source: source,
                active: active,
                version: version,
                pinned: pinned,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a acuity plan tier in status open.
    static func newAcuityPlanTier(_ code: String, name: String) -> AcuityPlanTier {
        return AcuityPlanTier(
            code: code,
            name: name,
            country: "",
            ward: "",
            retries: 0,
            source: "",
            active: false,
            version: 0,
            pinned: false,
            limit: 0,
            status: AcuityPlanTierStatus.`open`
        )
    }
}
