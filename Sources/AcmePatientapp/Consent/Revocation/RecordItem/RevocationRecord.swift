import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation record is in its life cycle.
    enum RevocationRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A revocation record as the revocation team keeps it.
    final class RevocationRecord {
        var code: String
        var label: String
        var ceiling: Double
        var ratio: Double
        var windowDays: Int
        var status: RevocationRecordStatus

        init(code: String, label: String, ceiling: Double, ratio: Double, windowDays: Int, status: RevocationRecordStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.ratio = ratio
            self.windowDays = windowDays
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

        func canMoveTo(_ next: RevocationRecordStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RevocationRecordStatus.suspended || next == RevocationRecordStatus.closed
            case .suspended:
                return next == RevocationRecordStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("revocation record") \(code)"
        }

        func effectiveValue() -> Double {
            return (ratio * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> RevocationRecord {
            return RevocationRecord(
                code: code,
                label: label,
                ceiling: ceiling,
                ratio: ratio,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a revocation record in status draft.
    static func newRevocationRecord(_ code: String, label: String) -> RevocationRecord {
        return RevocationRecord(
            code: code,
            label: label,
            ceiling: 0.0,
            ratio: 0.0,
            windowDays: 0,
            status: RevocationRecordStatus.draft
        )
    }
}
