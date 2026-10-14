import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal language ledger is in its life cycle.
    enum SeasonalLanguageLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A seasonal language ledger as the language team keeps it.
    final class SeasonalLanguageLedger {
        var code: String
        var label: String
        var revision: Int
        var clinicianID: String
        var region: String
        var status: SeasonalLanguageLedgerStatus

        init(code: String, label: String, revision: Int, clinicianID: String, region: String, status: SeasonalLanguageLedgerStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.clinicianID = clinicianID
            self.region = region
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

        func canMoveTo(_ next: SeasonalLanguageLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == SeasonalLanguageLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalLanguageLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal language ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> SeasonalLanguageLedger {
            return SeasonalLanguageLedger(
                code: code,
                label: label,
                revision: revision,
                clinicianID: clinicianID,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a seasonal language ledger in status open.
    static func newSeasonalLanguageLedger(_ code: String, label: String) -> SeasonalLanguageLedger {
        return SeasonalLanguageLedger(
            code: code,
            label: label,
            revision: 0,
            clinicianID: "",
            region: "",
            status: SeasonalLanguageLedgerStatus.`open`
        )
    }
}
