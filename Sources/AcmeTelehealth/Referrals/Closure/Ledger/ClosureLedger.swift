import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure ledger is in its life cycle.
    enum ClosureLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A closure ledger. Its code is unique within a tenant.
    final class ClosureLedger {
        var code: String
        var name: String
        var approved: Bool
        var attempts: Int
        var channel: String
        var status: ClosureLedgerStatus

        init(code: String, name: String, approved: Bool, attempts: Int, channel: String, status: ClosureLedgerStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.attempts = attempts
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClosureLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ClosureLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("closure ledger") \(code)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> ClosureLedger {
            return ClosureLedger(
                code: code,
                name: name,
                approved: approved,
                attempts: attempts,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a closure ledger in status new.
    static func newClosureLedger(_ code: String, name: String) -> ClosureLedger {
        return ClosureLedger(
            code: code,
            name: name,
            approved: false,
            attempts: 0,
            channel: "",
            status: ClosureLedgerStatus.new
        )
    }
}
