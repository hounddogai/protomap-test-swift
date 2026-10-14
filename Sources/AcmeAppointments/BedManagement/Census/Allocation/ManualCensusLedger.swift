import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual census ledger is in its life cycle.
    enum ManualCensusLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a manual census ledger and its current status.
    final class ManualCensusLedger {
        var code: String
        var name: String
        var createdAt: Int
        var capacity: Int
        var procedureCode: String
        var summary: String
        var durationMinutes: Int
        var refills: Int
        var locale: String
        var status: ManualCensusLedgerStatus

        init(code: String, name: String, createdAt: Int, capacity: Int, procedureCode: String, summary: String, durationMinutes: Int, refills: Int, locale: String, status: ManualCensusLedgerStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.capacity = capacity
            self.procedureCode = procedureCode
            self.summary = summary
            self.durationMinutes = durationMinutes
            self.refills = refills
            self.locale = locale
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

        func canMoveTo(_ next: ManualCensusLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ManualCensusLedgerStatus.resolved || next == ManualCensusLedgerStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualCensusLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual census ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return ((Double(refills) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> ManualCensusLedger {
            return ManualCensusLedger(
                code: code,
                name: name,
                createdAt: createdAt,
                capacity: capacity,
                procedureCode: procedureCode,
                summary: summary,
                durationMinutes: durationMinutes,
                refills: refills,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual census ledger in status open.
    static func newManualCensusLedger(_ code: String, name: String) -> ManualCensusLedger {
        return ManualCensusLedger(
            code: code,
            name: name,
            createdAt: 0,
            capacity: 0,
            procedureCode: "",
            summary: "",
            durationMinutes: 0,
            refills: 0,
            locale: "",
            status: ManualCensusLedgerStatus.`open`
        )
    }
}
