import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback program batch is in its life cycle.
    enum FallbackProgramBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One fallback program batch, with what the planners need to act on it.
    final class FallbackProgramBatch {
        var code: String
        var label: String
        var ratio: Double
        var windowDays: Int
        var score: Double
        var graceDays: Int
        var revision: Int
        var priority: Int
        var status: FallbackProgramBatchStatus

        init(code: String, label: String, ratio: Double, windowDays: Int, score: Double, graceDays: Int, revision: Int, priority: Int, status: FallbackProgramBatchStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.windowDays = windowDays
            self.score = score
            self.graceDays = graceDays
            self.revision = revision
            self.priority = priority
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

        func canMoveTo(_ next: FallbackProgramBatchStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackProgramBatchStatus.pending || next == FallbackProgramBatchStatus.active
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FallbackProgramBatchStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackProgramBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback program batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("fallback program batch") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(graceDays) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackProgramBatch {
            return FallbackProgramBatch(
                code: code,
                label: label,
                ratio: ratio,
                windowDays: windowDays,
                score: score,
                graceDays: graceDays,
                revision: revision,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback program batch in status draft.
    static func newFallbackProgramBatch(_ code: String, label: String) -> FallbackProgramBatch {
        return FallbackProgramBatch(
            code: code,
            label: label,
            ratio: 0.0,
            windowDays: 0,
            score: 0.0,
            graceDays: 0,
            revision: 0,
            priority: 0,
            status: FallbackProgramBatchStatus.draft
        )
    }
}
