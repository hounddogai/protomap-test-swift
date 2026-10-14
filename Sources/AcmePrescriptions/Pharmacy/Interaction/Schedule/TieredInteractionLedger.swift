import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered interaction ledger is in its life cycle.
    enum TieredInteractionLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered interaction ledger, with what the planners need to act on it.
    final class TieredInteractionLedger {
        var code: String
        var label: String
        var payer: String
        var currency: String
        var source: String
        var diagnosisCode: String
        var phone: String
        var facility: String
        var region: String
        var margin: Double
        var channel: String
        var status: TieredInteractionLedgerStatus

        init(code: String, label: String, payer: String, currency: String, source: String, diagnosisCode: String, phone: String, facility: String, region: String, margin: Double, channel: String, status: TieredInteractionLedgerStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.currency = currency
            self.source = source
            self.diagnosisCode = diagnosisCode
            self.phone = phone
            self.facility = facility
            self.region = region
            self.margin = margin
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredInteractionLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == TieredInteractionLedgerStatus.resolved || next == TieredInteractionLedgerStatus.archived
            case .resolved:
                return next == TieredInteractionLedgerStatus.archived
            case .reopened:
                return next == TieredInteractionLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredInteractionLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered interaction ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered interaction ledger") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> TieredInteractionLedger {
            return TieredInteractionLedger(
                code: code,
                label: label,
                payer: payer,
                currency: currency,
                source: source,
                diagnosisCode: diagnosisCode,
                phone: phone,
                facility: facility,
                region: region,
                margin: margin,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered interaction ledger in status open.
    static func newTieredInteractionLedger(_ code: String, label: String) -> TieredInteractionLedger {
        return TieredInteractionLedger(
            code: code,
            label: label,
            payer: "",
            currency: "",
            source: "",
            diagnosisCode: "",
            phone: "",
            facility: "",
            region: "",
            margin: 0.0,
            channel: "",
            status: TieredInteractionLedgerStatus.`open`
        )
    }
}
