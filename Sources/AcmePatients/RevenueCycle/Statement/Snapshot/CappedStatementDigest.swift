import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped statement digest is in its life cycle.
    enum CappedStatementDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One capped statement digest, with what the planners need to act on it.
    final class CappedStatementDigest {
        var code: String
        var label: String
        var summary: String
        var pinned: Bool
        var channel: String
        var amount: Double
        var status: CappedStatementDigestStatus

        init(code: String, label: String, summary: String, pinned: Bool, channel: String, amount: Double, status: CappedStatementDigestStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.pinned = pinned
            self.channel = channel
            self.amount = amount
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

        func canMoveTo(_ next: CappedStatementDigestStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedStatementDigestStatus.pending || next == CappedStatementDigestStatus.suspended
            case .pending:
                return next == CappedStatementDigestStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedStatementDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped statement digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped statement digest") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> CappedStatementDigest {
            return CappedStatementDigest(
                code: code,
                label: label,
                summary: summary,
                pinned: pinned,
                channel: channel,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped statement digest in status draft.
    static func newCappedStatementDigest(_ code: String, label: String) -> CappedStatementDigest {
        return CappedStatementDigest(
            code: code,
            label: label,
            summary: "",
            pinned: false,
            channel: "",
            amount: 0.0,
            status: CappedStatementDigestStatus.draft
        )
    }
}
