import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual task policy is in its life cycle.
    enum ManualTaskPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual task policy as the task team keeps it.
    final class ManualTaskPolicy {
        var code: String
        var label: String
        var segment: String
        var title: String
        var sequence: Int
        var status: ManualTaskPolicyStatus

        init(code: String, label: String, segment: String, title: String, sequence: Int, status: ManualTaskPolicyStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.title = title
            self.sequence = sequence
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

        func canMoveTo(_ next: ManualTaskPolicyStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ManualTaskPolicyStatus.closed
            case .active:
                return next == ManualTaskPolicyStatus.suspended || next == ManualTaskPolicyStatus.closed
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

        func moveTo(_ next: ManualTaskPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual task policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> ManualTaskPolicy {
            return ManualTaskPolicy(
                code: code,
                label: label,
                segment: segment,
                title: title,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual task policy in status draft.
    static func newManualTaskPolicy(_ code: String, label: String) -> ManualTaskPolicy {
        return ManualTaskPolicy(
            code: code,
            label: label,
            segment: "",
            title: "",
            sequence: 0,
            status: ManualTaskPolicyStatus.draft
        )
    }
}
