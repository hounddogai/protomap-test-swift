import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range allocation is in its life cycle.
    enum ReferenceRangeAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A reference range allocation as the reference range team keeps it.
    final class ReferenceRangeAllocation {
        var code: String
        var label: String
        var sequence: Int
        var revision: Int
        var dosageMg: Double
        var phone: String
        var tags: [String]
        var visible: Bool
        var status: ReferenceRangeAllocationStatus

        init(code: String, label: String, sequence: Int, revision: Int, dosageMg: Double, phone: String, tags: [String], visible: Bool, status: ReferenceRangeAllocationStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.revision = revision
            self.dosageMg = dosageMg
            self.phone = phone
            self.tags = tags
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ReferenceRangeAllocationStatus.cancelled
            case .completed:
                return next == ReferenceRangeAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveVolume() -> Double {
            return (Double(revision) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeAllocation {
            return ReferenceRangeAllocation(
                code: code,
                label: label,
                sequence: sequence,
                revision: revision,
                dosageMg: dosageMg,
                phone: phone,
                tags: tags,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a reference range allocation in status planned.
    static func newReferenceRangeAllocation(_ code: String, label: String) -> ReferenceRangeAllocation {
        return ReferenceRangeAllocation(
            code: code,
            label: label,
            sequence: 0,
            revision: 0,
            dosageMg: 0.0,
            phone: "",
            tags: [],
            visible: false,
            status: ReferenceRangeAllocationStatus.planned
        )
    }
}
