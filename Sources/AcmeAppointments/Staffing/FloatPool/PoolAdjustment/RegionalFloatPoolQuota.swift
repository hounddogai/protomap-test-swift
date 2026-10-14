import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional float pool quota is in its life cycle.
    enum RegionalFloatPoolQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A regional float pool quota as the float pool team keeps it.
    final class RegionalFloatPoolQuota {
        var code: String
        var title: String
        var capacity: Int
        var reviewer: String
        var refills: Int
        var status: RegionalFloatPoolQuotaStatus

        init(code: String, title: String, capacity: Int, reviewer: String, refills: Int, status: RegionalFloatPoolQuotaStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.reviewer = reviewer
            self.refills = refills
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

        func canMoveTo(_ next: RegionalFloatPoolQuotaStatus) -> Bool {
            switch status {
            case .requested:
                return next == RegionalFloatPoolQuotaStatus.revoked || next == RegionalFloatPoolQuotaStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RegionalFloatPoolQuotaStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalFloatPoolQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional float pool quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return ((Double(capacity) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalFloatPoolQuota {
            return RegionalFloatPoolQuota(
                code: code,
                title: title,
                capacity: capacity,
                reviewer: reviewer,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional float pool quota in status requested.
    static func newRegionalFloatPoolQuota(_ code: String, title: String) -> RegionalFloatPoolQuota {
        return RegionalFloatPoolQuota(
            code: code,
            title: title,
            capacity: 0,
            reviewer: "",
            refills: 0,
            status: RegionalFloatPoolQuotaStatus.requested
        )
    }
}
