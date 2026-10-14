import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement snapshot is in its life cycle.
    enum StatementSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A statement snapshot as the statement team keeps it.
    final class StatementSnapshot {
        var code: String
        var title: String
        var sequence: Int
        var description: String
        var attempts: Int
        var label: String
        var name: String
        var allergy: String
        var status: StatementSnapshotStatus

        init(code: String, title: String, sequence: Int, description: String, attempts: Int, label: String, name: String, allergy: String, status: StatementSnapshotStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.description = description
            self.attempts = attempts
            self.label = label
            self.name = name
            self.allergy = allergy
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

        func canMoveTo(_ next: StatementSnapshotStatus) -> Bool {
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
                return next == StatementSnapshotStatus.done
            case .running:
                return next == StatementSnapshotStatus.done || next == StatementSnapshotStatus.failed
            case .done:
                return next == StatementSnapshotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return ((Double(sequence) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> StatementSnapshot {
            return StatementSnapshot(
                code: code,
                title: title,
                sequence: sequence,
                description: description,
                attempts: attempts,
                label: label,
                name: name,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a statement snapshot in status new.
    static func newStatementSnapshot(_ code: String, title: String) -> StatementSnapshot {
        return StatementSnapshot(
            code: code,
            title: title,
            sequence: 0,
            description: "",
            attempts: 0,
            label: "",
            name: "",
            allergy: "",
            status: StatementSnapshotStatus.new
        )
    }
}
