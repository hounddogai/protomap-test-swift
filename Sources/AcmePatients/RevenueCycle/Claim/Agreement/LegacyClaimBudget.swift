import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy claim budget is in its life cycle.
    enum LegacyClaimBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy claim budget. Its code is unique within a tenant.
    final class LegacyClaimBudget {
        var code: String
        var title: String
        var rate: Double
        var ward: String
        var attributes: [String: String]
        var reviewer: String
        var status: LegacyClaimBudgetStatus

        init(code: String, title: String, rate: Double, ward: String, attributes: [String: String], reviewer: String, status: LegacyClaimBudgetStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.ward = ward
            self.attributes = attributes
            self.reviewer = reviewer
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

        func canMoveTo(_ next: LegacyClaimBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == LegacyClaimBudgetStatus.withdrawn
            case .rejected:
                return next == LegacyClaimBudgetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyClaimBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy claim budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> LegacyClaimBudget {
            return LegacyClaimBudget(
                code: code,
                title: title,
                rate: rate,
                ward: ward,
                attributes: attributes,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy claim budget in status proposed.
    static func newLegacyClaimBudget(_ code: String, title: String) -> LegacyClaimBudget {
        return LegacyClaimBudget(
            code: code,
            title: title,
            rate: 0.0,
            ward: "",
            attributes: [:],
            reviewer: "",
            status: LegacyClaimBudgetStatus.proposed
        )
    }
}
