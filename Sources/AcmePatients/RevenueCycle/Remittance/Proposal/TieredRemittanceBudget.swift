import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered remittance budget is in its life cycle.
    enum TieredRemittanceBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One tiered remittance budget, with what the planners need to act on it.
    final class TieredRemittanceBudget {
        var code: String
        var name: String
        var ratio: Double
        var durationMinutes: Int
        var phone: String
        var ward: String
        var timezone: String
        var tags: [String]
        var maximum: Double
        var version: Int
        var score: Double
        var status: TieredRemittanceBudgetStatus

        init(code: String, name: String, ratio: Double, durationMinutes: Int, phone: String, ward: String, timezone: String, tags: [String], maximum: Double, version: Int, score: Double, status: TieredRemittanceBudgetStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.durationMinutes = durationMinutes
            self.phone = phone
            self.ward = ward
            self.timezone = timezone
            self.tags = tags
            self.maximum = maximum
            self.version = version
            self.score = score
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

        func canMoveTo(_ next: TieredRemittanceBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == TieredRemittanceBudgetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRemittanceBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered remittance budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return ((score + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> TieredRemittanceBudget {
            return TieredRemittanceBudget(
                code: code,
                name: name,
                ratio: ratio,
                durationMinutes: durationMinutes,
                phone: phone,
                ward: ward,
                timezone: timezone,
                tags: tags,
                maximum: maximum,
                version: version,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a tiered remittance budget in status proposed.
    static func newTieredRemittanceBudget(_ code: String, name: String) -> TieredRemittanceBudget {
        return TieredRemittanceBudget(
            code: code,
            name: name,
            ratio: 0.0,
            durationMinutes: 0,
            phone: "",
            ward: "",
            timezone: "",
            tags: [],
            maximum: 0.0,
            version: 0,
            score: 0.0,
            status: TieredRemittanceBudgetStatus.proposed
        )
    }
}
