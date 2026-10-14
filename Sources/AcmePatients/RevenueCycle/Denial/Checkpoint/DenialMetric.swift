import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial metric is in its life cycle.
    enum DenialMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A denial metric. Its code is unique within a tenant.
    final class DenialMetric {
        var code: String
        var name: String
        var expiresAt: Int
        var threshold: Double
        var updatedAt: Int
        var retries: Int
        var discount: Double
        var active: Bool
        var checksum: String
        var status: DenialMetricStatus

        init(code: String, name: String, expiresAt: Int, threshold: Double, updatedAt: Int, retries: Int, discount: Double, active: Bool, checksum: String, status: DenialMetricStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.threshold = threshold
            self.updatedAt = updatedAt
            self.retries = retries
            self.discount = discount
            self.active = active
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DenialMetricStatus) -> Bool {
            switch status {
            case .draft:
                return next == DenialMetricStatus.active
            case .pending:
                return next == DenialMetricStatus.active || next == DenialMetricStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == DenialMetricStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return (discount * threshold * 100).rounded() / 100
        }

        func copyValue() -> DenialMetric {
            return DenialMetric(
                code: code,
                name: name,
                expiresAt: expiresAt,
                threshold: threshold,
                updatedAt: updatedAt,
                retries: retries,
                discount: discount,
                active: active,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a denial metric in status draft.
    static func newDenialMetric(_ code: String, name: String) -> DenialMetric {
        return DenialMetric(
            code: code,
            name: name,
            expiresAt: 0,
            threshold: 0.0,
            updatedAt: 0,
            retries: 0,
            discount: 0.0,
            active: false,
            checksum: "",
            status: DenialMetricStatus.draft
        )
    }
}
