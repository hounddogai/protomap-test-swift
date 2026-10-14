import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped courier rollup is in its life cycle.
    enum CappedCourierRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A capped courier rollup as the courier team keeps it.
    final class CappedCourierRollup {
        var code: String
        var name: String
        var attributes: [String: String]
        var timezone: String
        var visitMinutes: Int
        var cost: Double
        var endsAt: Int
        var status: CappedCourierRollupStatus

        init(code: String, name: String, attributes: [String: String], timezone: String, visitMinutes: Int, cost: Double, endsAt: Int, status: CappedCourierRollupStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.timezone = timezone
            self.visitMinutes = visitMinutes
            self.cost = cost
            self.endsAt = endsAt
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

        func canMoveTo(_ next: CappedCourierRollupStatus) -> Bool {
            switch status {
            case .requested:
                return next == CappedCourierRollupStatus.expired
            case .granted:
                return next == CappedCourierRollupStatus.expired
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

        func moveTo(_ next: CappedCourierRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped courier rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
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

        func effectiveExposure() -> Double {
            return ((Double(endsAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCourierRollup {
            return CappedCourierRollup(
                code: code,
                name: name,
                attributes: attributes,
                timezone: timezone,
                visitMinutes: visitMinutes,
                cost: cost,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped courier rollup in status requested.
    static func newCappedCourierRollup(_ code: String, name: String) -> CappedCourierRollup {
        return CappedCourierRollup(
            code: code,
            name: name,
            attributes: [:],
            timezone: "",
            visitMinutes: 0,
            cost: 0.0,
            endsAt: 0,
            status: CappedCourierRollupStatus.requested
        )
    }
}
