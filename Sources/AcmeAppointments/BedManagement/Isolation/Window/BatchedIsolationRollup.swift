import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched isolation rollup is in its life cycle.
    enum BatchedIsolationRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched isolation rollup as the isolation team keeps it.
    final class BatchedIsolationRollup {
        var code: String
        var title: String
        var score: Double
        var graceDays: Int
        var category: String
        var description: String
        var version: Int
        var attempts: Int
        var margin: Double
        var status: BatchedIsolationRollupStatus

        init(code: String, title: String, score: Double, graceDays: Int, category: String, description: String, version: Int, attempts: Int, margin: Double, status: BatchedIsolationRollupStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.graceDays = graceDays
            self.category = category
            self.description = description
            self.version = version
            self.attempts = attempts
            self.margin = margin
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

        func canMoveTo(_ next: BatchedIsolationRollupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedIsolationRollupStatus.done || next == BatchedIsolationRollupStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BatchedIsolationRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedIsolationRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched isolation rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("batched isolation rollup") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(attempts) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedIsolationRollup {
            return BatchedIsolationRollup(
                code: code,
                title: title,
                score: score,
                graceDays: graceDays,
                category: category,
                description: description,
                version: version,
                attempts: attempts,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched isolation rollup in status new.
    static func newBatchedIsolationRollup(_ code: String, title: String) -> BatchedIsolationRollup {
        return BatchedIsolationRollup(
            code: code,
            title: title,
            score: 0.0,
            graceDays: 0,
            category: "",
            description: "",
            version: 0,
            attempts: 0,
            margin: 0.0,
            status: BatchedIsolationRollupStatus.new
        )
    }
}
