import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional charge metric is in its life cycle.
    enum RegionalChargeMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One regional charge metric, with what the planners need to act on it.
    final class RegionalChargeMetric {
        var code: String
        var title: String
        var visible: Bool
        var graceDays: Int
        var revision: Int
        var updatedAt: Int
        var status: RegionalChargeMetricStatus

        init(code: String, title: String, visible: Bool, graceDays: Int, revision: Int, updatedAt: Int, status: RegionalChargeMetricStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.graceDays = graceDays
            self.revision = revision
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: RegionalChargeMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RegionalChargeMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalChargeMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional charge metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveExposure() -> Double {
            return ((Double(graceDays) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalChargeMetric {
            return RegionalChargeMetric(
                code: code,
                title: title,
                visible: visible,
                graceDays: graceDays,
                revision: revision,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional charge metric in status requested.
    static func newRegionalChargeMetric(_ code: String, title: String) -> RegionalChargeMetric {
        return RegionalChargeMetric(
            code: code,
            title: title,
            visible: false,
            graceDays: 0,
            revision: 0,
            updatedAt: 0,
            status: RegionalChargeMetricStatus.requested
        )
    }
}
