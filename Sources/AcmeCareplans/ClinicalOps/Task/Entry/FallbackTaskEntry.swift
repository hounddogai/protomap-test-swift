import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback task entry is in its life cycle.
    enum FallbackTaskEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback task entry as the task team keeps it.
    final class FallbackTaskEntry {
        var code: String
        var title: String
        var ratio: Double
        var retries: Int
        var category: String
        var refills: Int
        var score: Double
        var status: FallbackTaskEntryStatus

        init(code: String, title: String, ratio: Double, retries: Int, category: String, refills: Int, score: Double, status: FallbackTaskEntryStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.retries = retries
            self.category = category
            self.refills = refills
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackTaskEntryStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackTaskEntryStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FallbackTaskEntryStatus.draining
            case .draining:
                return next == FallbackTaskEntryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackTaskEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback task entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback task entry") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(refills) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackTaskEntry {
            return FallbackTaskEntry(
                code: code,
                title: title,
                ratio: ratio,
                retries: retries,
                category: category,
                refills: refills,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback task entry in status idle.
    static func newFallbackTaskEntry(_ code: String, title: String) -> FallbackTaskEntry {
        return FallbackTaskEntry(
            code: code,
            title: title,
            ratio: 0.0,
            retries: 0,
            category: "",
            refills: 0,
            score: 0.0,
            status: FallbackTaskEntryStatus.idle
        )
    }
}
