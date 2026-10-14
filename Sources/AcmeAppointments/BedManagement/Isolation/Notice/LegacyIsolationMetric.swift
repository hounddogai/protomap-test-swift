import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy isolation metric is in its life cycle.
    enum LegacyIsolationMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a legacy isolation metric and its current status.
    final class LegacyIsolationMetric {
        var code: String
        var name: String
        var channel: String
        var facility: String
        var graceDays: Int
        var visitMinutes: Int
        var active: Bool
        var startsAt: Int
        var status: LegacyIsolationMetricStatus

        init(code: String, name: String, channel: String, facility: String, graceDays: Int, visitMinutes: Int, active: Bool, startsAt: Int, status: LegacyIsolationMetricStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.facility = facility
            self.graceDays = graceDays
            self.visitMinutes = visitMinutes
            self.active = active
            self.startsAt = startsAt
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

        func canMoveTo(_ next: LegacyIsolationMetricStatus) -> Bool {
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
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LegacyIsolationMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyIsolationMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy isolation metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netExposure() -> Double {
            return ((Double(visitMinutes) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyIsolationMetric {
            return LegacyIsolationMetric(
                code: code,
                name: name,
                channel: channel,
                facility: facility,
                graceDays: graceDays,
                visitMinutes: visitMinutes,
                active: active,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy isolation metric in status requested.
    static func newLegacyIsolationMetric(_ code: String, name: String) -> LegacyIsolationMetric {
        return LegacyIsolationMetric(
            code: code,
            name: name,
            channel: "",
            facility: "",
            graceDays: 0,
            visitMinutes: 0,
            active: false,
            startsAt: 0,
            status: LegacyIsolationMetricStatus.requested
        )
    }
}
