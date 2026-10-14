import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered substitution override is in its life cycle.
    enum TieredSubstitutionOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One tiered substitution override, with what the planners need to act on it.
    final class TieredSubstitutionOverride {
        var code: String
        var label: String
        var country: String
        var limit: Int
        var approved: Bool
        var channel: String
        var amount: Double
        var region: String
        var quantity: Int
        var checksum: String
        var procedureCode: String
        var status: TieredSubstitutionOverrideStatus

        init(code: String, label: String, country: String, limit: Int, approved: Bool, channel: String, amount: Double, region: String, quantity: Int, checksum: String, procedureCode: String, status: TieredSubstitutionOverrideStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.limit = limit
            self.approved = approved
            self.channel = channel
            self.amount = amount
            self.region = region
            self.quantity = quantity
            self.checksum = checksum
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: TieredSubstitutionOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredSubstitutionOverrideStatus.pending
            case .pending:
                return next == TieredSubstitutionOverrideStatus.suspended || next == TieredSubstitutionOverrideStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredSubstitutionOverrideStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredSubstitutionOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered substitution override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((Double(quantity) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> TieredSubstitutionOverride {
            return TieredSubstitutionOverride(
                code: code,
                label: label,
                country: country,
                limit: limit,
                approved: approved,
                channel: channel,
                amount: amount,
                region: region,
                quantity: quantity,
                checksum: checksum,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered substitution override in status draft.
    static func newTieredSubstitutionOverride(_ code: String, label: String) -> TieredSubstitutionOverride {
        return TieredSubstitutionOverride(
            code: code,
            label: label,
            country: "",
            limit: 0,
            approved: false,
            channel: "",
            amount: 0.0,
            region: "",
            quantity: 0,
            checksum: "",
            procedureCode: "",
            status: TieredSubstitutionOverrideStatus.draft
        )
    }
}
