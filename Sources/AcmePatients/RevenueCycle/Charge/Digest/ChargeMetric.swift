import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge metric is in its life cycle.
    enum ChargeMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A charge metric. Its code is unique within a tenant.
    final class ChargeMetric {
        var code: String
        var title: String
        var updatedAt: Int
        var description: String
        var bed: String
        var status: ChargeMetricStatus

        init(code: String, title: String, updatedAt: Int, description: String, bed: String, status: ChargeMetricStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.description = description
            self.bed = bed
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

        func canMoveTo(_ next: ChargeMetricStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ChargeMetricStatus.rejected
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

        func moveTo(_ next: ChargeMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("charge metric") \(code)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> ChargeMetric {
            return ChargeMetric(
                code: code,
                title: title,
                updatedAt: updatedAt,
                description: description,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a charge metric in status proposed.
    static func newChargeMetric(_ code: String, title: String) -> ChargeMetric {
        return ChargeMetric(
            code: code,
            title: title,
            updatedAt: 0,
            description: "",
            bed: "",
            status: ChargeMetricStatus.proposed
        )
    }
}
