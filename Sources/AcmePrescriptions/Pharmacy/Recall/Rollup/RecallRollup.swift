import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall rollup is in its life cycle.
    enum RecallRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A recall rollup. Its code is unique within a tenant.
    final class RecallRollup {
        var code: String
        var name: String
        var approved: Bool
        var description: String
        var region: String
        var reviewer: String
        var currency: String
        var cost: Double
        var payer: String
        var status: RecallRollupStatus

        init(code: String, name: String, approved: Bool, description: String, region: String, reviewer: String, currency: String, cost: Double, payer: String, status: RecallRollupStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.description = description
            self.region = region
            self.reviewer = reviewer
            self.currency = currency
            self.cost = cost
            self.payer = payer
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

        func canMoveTo(_ next: RecallRollupStatus) -> Bool {
            switch status {
            case .requested:
                return next == RecallRollupStatus.expired
            case .granted:
                return next == RecallRollupStatus.revoked || next == RecallRollupStatus.expired
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

        func moveTo(_ next: RecallRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> RecallRollup {
            return RecallRollup(
                code: code,
                name: name,
                approved: approved,
                description: description,
                region: region,
                reviewer: reviewer,
                currency: currency,
                cost: cost,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a recall rollup in status requested.
    static func newRecallRollup(_ code: String, name: String) -> RecallRollup {
        return RecallRollup(
            code: code,
            name: name,
            approved: false,
            description: "",
            region: "",
            reviewer: "",
            currency: "",
            cost: 0.0,
            payer: "",
            status: RecallRollupStatus.requested
        )
    }
}
