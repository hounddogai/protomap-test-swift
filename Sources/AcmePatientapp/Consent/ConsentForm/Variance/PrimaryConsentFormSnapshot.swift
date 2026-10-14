import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary consent form snapshot is in its life cycle.
    enum PrimaryConsentFormSnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary consent form snapshot and its current status.
    final class PrimaryConsentFormSnapshot {
        var code: String
        var label: String
        var name: String
        var score: Double
        var attempts: Int
        var status: PrimaryConsentFormSnapshotStatus

        init(code: String, label: String, name: String, score: Double, attempts: Int, status: PrimaryConsentFormSnapshotStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.score = score
            self.attempts = attempts
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

        func canMoveTo(_ next: PrimaryConsentFormSnapshotStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryConsentFormSnapshotStatus.suspended || next == PrimaryConsentFormSnapshotStatus.closed
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

        func moveTo(_ next: PrimaryConsentFormSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary consent form snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return ((score + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryConsentFormSnapshot {
            return PrimaryConsentFormSnapshot(
                code: code,
                label: label,
                name: name,
                score: score,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary consent form snapshot in status draft.
    static func newPrimaryConsentFormSnapshot(_ code: String, label: String) -> PrimaryConsentFormSnapshot {
        return PrimaryConsentFormSnapshot(
            code: code,
            label: label,
            name: "",
            score: 0.0,
            attempts: 0,
            status: PrimaryConsentFormSnapshotStatus.draft
        )
    }
}
