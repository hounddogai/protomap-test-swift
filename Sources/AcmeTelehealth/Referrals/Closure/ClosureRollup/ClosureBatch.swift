import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure batch is in its life cycle.
    enum ClosureBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A closure batch as the closure team keeps it.
    final class ClosureBatch {
        var code: String
        var label: String
        var patientRef: String
        var threshold: Double
        var graceDays: Int
        var maximum: Double
        var tags: [String]
        var facility: String
        var ceiling: Double
        var status: ClosureBatchStatus

        init(code: String, label: String, patientRef: String, threshold: Double, graceDays: Int, maximum: Double, tags: [String], facility: String, ceiling: Double, status: ClosureBatchStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.threshold = threshold
            self.graceDays = graceDays
            self.maximum = maximum
            self.tags = tags
            self.facility = facility
            self.ceiling = ceiling
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

        func canMoveTo(_ next: ClosureBatchStatus) -> Bool {
            switch status {
            case .draft:
                return next == ClosureBatchStatus.active
            case .pending:
                return next == ClosureBatchStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: ClosureBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return ((Double(graceDays) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> ClosureBatch {
            return ClosureBatch(
                code: code,
                label: label,
                patientRef: patientRef,
                threshold: threshold,
                graceDays: graceDays,
                maximum: maximum,
                tags: tags,
                facility: facility,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a closure batch in status draft.
    static func newClosureBatch(_ code: String, label: String) -> ClosureBatch {
        return ClosureBatch(
            code: code,
            label: label,
            patientRef: "",
            threshold: 0.0,
            graceDays: 0,
            maximum: 0.0,
            tags: [],
            facility: "",
            ceiling: 0.0,
            status: ClosureBatchStatus.draft
        )
    }
}
