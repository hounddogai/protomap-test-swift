import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff ledger is in its life cycle.
    enum HandoffLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A handoff ledger as the handoff team keeps it.
    final class HandoffLedger {
        var code: String
        var title: String
        var maximum: Double
        var threshold: Double
        var summary: String
        var minimum: Double
        var status: HandoffLedgerStatus

        init(code: String, title: String, maximum: Double, threshold: Double, summary: String, minimum: Double, status: HandoffLedgerStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.threshold = threshold
            self.summary = summary
            self.minimum = minimum
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

        func canMoveTo(_ next: HandoffLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == HandoffLedgerStatus.running || next == HandoffLedgerStatus.failed
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

        func moveTo(_ next: HandoffLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedTotal() -> Double {
            return ((threshold - minimum) * 100).rounded() / 100
        }

        func copyValue() -> HandoffLedger {
            return HandoffLedger(
                code: code,
                title: title,
                maximum: maximum,
                threshold: threshold,
                summary: summary,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a handoff ledger in status new.
    static func newHandoffLedger(_ code: String, title: String) -> HandoffLedger {
        return HandoffLedger(
            code: code,
            title: title,
            maximum: 0.0,
            threshold: 0.0,
            summary: "",
            minimum: 0.0,
            status: HandoffLedgerStatus.new
        )
    }
}
