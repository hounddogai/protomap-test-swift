import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure metric is in its life cycle.
    enum ClosureMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A closure metric as the closure team keeps it.
    final class ClosureMetric {
        var code: String
        var title: String
        var version: Int
        var retries: Int
        var source: String
        var status: ClosureMetricStatus

        init(code: String, title: String, version: Int, retries: Int, source: String, status: ClosureMetricStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.retries = retries
            self.source = source
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

        func canMoveTo(_ next: ClosureMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == ClosureMetricStatus.revoked || next == ClosureMetricStatus.expired
            case .granted:
                return next == ClosureMetricStatus.expired
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

        func moveTo(_ next: ClosureMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("closure metric") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(version) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ClosureMetric {
            return ClosureMetric(
                code: code,
                title: title,
                version: version,
                retries: retries,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a closure metric in status requested.
    static func newClosureMetric(_ code: String, title: String) -> ClosureMetric {
        return ClosureMetric(
            code: code,
            title: title,
            version: 0,
            retries: 0,
            source: "",
            status: ClosureMetricStatus.requested
        )
    }
}
