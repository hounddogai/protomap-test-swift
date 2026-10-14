import AcmePlatform
import Foundation

extension Consent {
    /// Where a default consent form ledger is in its life cycle.
    enum DefaultConsentFormLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a default consent form ledger and its current status.
    final class DefaultConsentFormLedger {
        var code: String
        var name: String
        var facility: String
        var patientRef: String
        var summary: String
        var category: String
        var durationMinutes: Int
        var currency: String
        var threshold: Double
        var timezone: String
        var status: DefaultConsentFormLedgerStatus

        init(code: String, name: String, facility: String, patientRef: String, summary: String, category: String, durationMinutes: Int, currency: String, threshold: Double, timezone: String, status: DefaultConsentFormLedgerStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.patientRef = patientRef
            self.summary = summary
            self.category = category
            self.durationMinutes = durationMinutes
            self.currency = currency
            self.threshold = threshold
            self.timezone = timezone
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

        func canMoveTo(_ next: DefaultConsentFormLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == DefaultConsentFormLedgerStatus.reopened || next == DefaultConsentFormLedgerStatus.archived
            case .resolved:
                return next == DefaultConsentFormLedgerStatus.reopened || next == DefaultConsentFormLedgerStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: DefaultConsentFormLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default consent form ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return ((threshold + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultConsentFormLedger {
            return DefaultConsentFormLedger(
                code: code,
                name: name,
                facility: facility,
                patientRef: patientRef,
                summary: summary,
                category: category,
                durationMinutes: durationMinutes,
                currency: currency,
                threshold: threshold,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default consent form ledger in status open.
    static func newDefaultConsentFormLedger(_ code: String, name: String) -> DefaultConsentFormLedger {
        return DefaultConsentFormLedger(
            code: code,
            name: name,
            facility: "",
            patientRef: "",
            summary: "",
            category: "",
            durationMinutes: 0,
            currency: "",
            threshold: 0.0,
            timezone: "",
            status: DefaultConsentFormLedgerStatus.`open`
        )
    }
}
