import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict inventory rollup is in its life cycle.
    enum StrictInventoryRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a strict inventory rollup and its current status.
    final class StrictInventoryRollup {
        var code: String
        var title: String
        var externalRef: String
        var cost: Double
        var notes: String
        var score: Double
        var status: StrictInventoryRollupStatus

        init(code: String, title: String, externalRef: String, cost: Double, notes: String, score: Double, status: StrictInventoryRollupStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.cost = cost
            self.notes = notes
            self.score = score
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

        func canMoveTo(_ next: StrictInventoryRollupStatus) -> Bool {
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
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == StrictInventoryRollupStatus.done || next == StrictInventoryRollupStatus.failed
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

        func moveTo(_ next: StrictInventoryRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict inventory rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return ((cost - score) * 100).rounded() / 100
        }

        func copyValue() -> StrictInventoryRollup {
            return StrictInventoryRollup(
                code: code,
                title: title,
                externalRef: externalRef,
                cost: cost,
                notes: notes,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict inventory rollup in status new.
    static func newStrictInventoryRollup(_ code: String, title: String) -> StrictInventoryRollup {
        return StrictInventoryRollup(
            code: code,
            title: title,
            externalRef: "",
            cost: 0.0,
            notes: "",
            score: 0.0,
            status: StrictInventoryRollupStatus.new
        )
    }
}
