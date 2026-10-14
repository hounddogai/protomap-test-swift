import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped disclosure ledger is in its life cycle.
    enum CappedDisclosureLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a capped disclosure ledger and its current status.
    final class CappedDisclosureLedger {
        var code: String
        var name: String
        var windowDays: Int
        var budget: Double
        var updatedAt: Int
        var startsAt: Int
        var notes: String
        var region: String
        var status: CappedDisclosureLedgerStatus

        init(code: String, name: String, windowDays: Int, budget: Double, updatedAt: Int, startsAt: Int, notes: String, region: String, status: CappedDisclosureLedgerStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.budget = budget
            self.updatedAt = updatedAt
            self.startsAt = startsAt
            self.notes = notes
            self.region = region
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

        func canMoveTo(_ next: CappedDisclosureLedgerStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedDisclosureLedgerStatus.active || next == CappedDisclosureLedgerStatus.suspended
            case .pending:
                return next == CappedDisclosureLedgerStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CappedDisclosureLedgerStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedDisclosureLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped disclosure ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedValue() -> Double {
            return ((budget + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedDisclosureLedger {
            return CappedDisclosureLedger(
                code: code,
                name: name,
                windowDays: windowDays,
                budget: budget,
                updatedAt: updatedAt,
                startsAt: startsAt,
                notes: notes,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped disclosure ledger in status draft.
    static func newCappedDisclosureLedger(_ code: String, name: String) -> CappedDisclosureLedger {
        return CappedDisclosureLedger(
            code: code,
            name: name,
            windowDays: 0,
            budget: 0.0,
            updatedAt: 0,
            startsAt: 0,
            notes: "",
            region: "",
            status: CappedDisclosureLedgerStatus.draft
        )
    }
}
