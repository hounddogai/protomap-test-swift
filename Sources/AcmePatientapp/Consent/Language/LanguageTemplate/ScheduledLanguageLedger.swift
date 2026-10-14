import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled language ledger is in its life cycle.
    enum ScheduledLanguageLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One scheduled language ledger, with what the planners need to act on it.
    final class ScheduledLanguageLedger {
        var code: String
        var name: String
        var margin: Double
        var approved: Bool
        var acuity: Int
        var specialty: String
        var status: ScheduledLanguageLedgerStatus

        init(code: String, name: String, margin: Double, approved: Bool, acuity: Int, specialty: String, status: ScheduledLanguageLedgerStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.approved = approved
            self.acuity = acuity
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledLanguageLedgerStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ScheduledLanguageLedgerStatus.draining
            case .ready:
                return next == ScheduledLanguageLedgerStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ScheduledLanguageLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled language ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedTotal() -> Double {
            return ((Double(acuity) - margin) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledLanguageLedger {
            return ScheduledLanguageLedger(
                code: code,
                name: name,
                margin: margin,
                approved: approved,
                acuity: acuity,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled language ledger in status idle.
    static func newScheduledLanguageLedger(_ code: String, name: String) -> ScheduledLanguageLedger {
        return ScheduledLanguageLedger(
            code: code,
            name: name,
            margin: 0.0,
            approved: false,
            acuity: 0,
            specialty: "",
            status: ScheduledLanguageLedgerStatus.idle
        )
    }
}
