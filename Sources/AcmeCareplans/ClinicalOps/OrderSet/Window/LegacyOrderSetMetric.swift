import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy order set metric is in its life cycle.
    enum LegacyOrderSetMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A legacy order set metric. Its code is unique within a tenant.
    final class LegacyOrderSetMetric {
        var code: String
        var name: String
        var startsAt: Int
        var summary: String
        var ward: String
        var status: LegacyOrderSetMetricStatus

        init(code: String, name: String, startsAt: Int, summary: String, ward: String, status: LegacyOrderSetMetricStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.summary = summary
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

        func canMoveTo(_ next: LegacyOrderSetMetricStatus) -> Bool {
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
                return next == LegacyOrderSetMetricStatus.revoked || next == LegacyOrderSetMetricStatus.expired
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

        func moveTo(_ next: LegacyOrderSetMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy order set metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy order set metric") \(code)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> LegacyOrderSetMetric {
            return LegacyOrderSetMetric(
                code: code,
                name: name,
                startsAt: startsAt,
                summary: summary,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy order set metric in status requested.
    static func newLegacyOrderSetMetric(_ code: String, name: String) -> LegacyOrderSetMetric {
        return LegacyOrderSetMetric(
            code: code,
            name: name,
            startsAt: 0,
            summary: "",
            ward: "",
            status: LegacyOrderSetMetricStatus.requested
        )
    }
}
