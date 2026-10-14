import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study ledger is in its life cycle.
    enum StudyLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One study ledger, with what the planners need to act on it.
    final class StudyLedger {
        var code: String
        var label: String
        var archived: Bool
        var margin: Double
        var quantity: Int
        var status: StudyLedgerStatus

        init(code: String, label: String, archived: Bool, margin: Double, quantity: Int, status: StudyLedgerStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.margin = margin
            self.quantity = quantity
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

        func canMoveTo(_ next: StudyLedgerStatus) -> Bool {
            switch status {
            case .new:
                return next == StudyLedgerStatus.done
            case .queued:
                return next == StudyLedgerStatus.done || next == StudyLedgerStatus.failed
            case .running:
                return next == StudyLedgerStatus.failed
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

        func moveTo(_ next: StudyLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("study ledger") \(code)"
        }

        func netValue() -> Double {
            return ((Double(quantity) - margin) * 100).rounded() / 100
        }

        func copyValue() -> StudyLedger {
            return StudyLedger(
                code: code,
                label: label,
                archived: archived,
                margin: margin,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a study ledger in status new.
    static func newStudyLedger(_ code: String, label: String) -> StudyLedger {
        return StudyLedger(
            code: code,
            label: label,
            archived: false,
            margin: 0.0,
            quantity: 0,
            status: StudyLedgerStatus.new
        )
    }
}
