import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted consent form ledger is in its life cycle.
    enum WeightedConsentFormLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a weighted consent form ledger and its current status.
    final class WeightedConsentFormLedger {
        var code: String
        var name: String
        var payer: String
        var margin: Double
        var facility: String
        var batchSize: Int
        var locale: String
        var currency: String
        var endsAt: Int
        var ownerID: String
        var status: WeightedConsentFormLedgerStatus

        init(code: String, name: String, payer: String, margin: Double, facility: String, batchSize: Int, locale: String, currency: String, endsAt: Int, ownerID: String, status: WeightedConsentFormLedgerStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.margin = margin
            self.facility = facility
            self.batchSize = batchSize
            self.locale = locale
            self.currency = currency
            self.endsAt = endsAt
            self.ownerID = ownerID
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

        func canMoveTo(_ next: WeightedConsentFormLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == WeightedConsentFormLedgerStatus.suspended || next == WeightedConsentFormLedgerStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: WeightedConsentFormLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted consent form ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return ((Double(batchSize) + margin) * 100).rounded() / 100
        }

        func copyValue() -> WeightedConsentFormLedger {
            return WeightedConsentFormLedger(
                code: code,
                name: name,
                payer: payer,
                margin: margin,
                facility: facility,
                batchSize: batchSize,
                locale: locale,
                currency: currency,
                endsAt: endsAt,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted consent form ledger in status draft.
    static func newWeightedConsentFormLedger(_ code: String, name: String) -> WeightedConsentFormLedger {
        return WeightedConsentFormLedger(
            code: code,
            name: name,
            payer: "",
            margin: 0.0,
            facility: "",
            batchSize: 0,
            locale: "",
            currency: "",
            endsAt: 0,
            ownerID: "",
            status: WeightedConsentFormLedgerStatus.draft
        )
    }
}
