import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal remittance policy is in its life cycle.
    enum SeasonalRemittancePolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a seasonal remittance policy and its current status.
    final class SeasonalRemittancePolicy {
        var code: String
        var title: String
        var checksum: String
        var externalRef: String
        var approved: Bool
        var ratio: Double
        var amount: Double
        var payer: String
        var status: SeasonalRemittancePolicyStatus

        init(code: String, title: String, checksum: String, externalRef: String, approved: Bool, ratio: Double, amount: Double, payer: String, status: SeasonalRemittancePolicyStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.externalRef = externalRef
            self.approved = approved
            self.ratio = ratio
            self.amount = amount
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalRemittancePolicyStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SeasonalRemittancePolicyStatus.published || next == SeasonalRemittancePolicyStatus.retired
            case .published:
                return next == SeasonalRemittancePolicyStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalRemittancePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal remittance policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal remittance policy") \(code)"
        }

        func weightedVolume() -> Double {
            return (ratio * amount * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRemittancePolicy {
            return SeasonalRemittancePolicy(
                code: code,
                title: title,
                checksum: checksum,
                externalRef: externalRef,
                approved: approved,
                ratio: ratio,
                amount: amount,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal remittance policy in status created.
    static func newSeasonalRemittancePolicy(_ code: String, title: String) -> SeasonalRemittancePolicy {
        return SeasonalRemittancePolicy(
            code: code,
            title: title,
            checksum: "",
            externalRef: "",
            approved: false,
            ratio: 0.0,
            amount: 0.0,
            payer: "",
            status: SeasonalRemittancePolicyStatus.created
        )
    }
}
