import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist rollup is in its life cycle.
    enum WorklistRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a worklist rollup and its current status.
    final class WorklistRollup {
        var code: String
        var title: String
        var acuity: Int
        var country: String
        var name: String
        var status: WorklistRollupStatus

        init(code: String, title: String, acuity: Int, country: String, name: String, status: WorklistRollupStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.country = country
            self.name = name
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

        func canMoveTo(_ next: WorklistRollupStatus) -> Bool {
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
                return next == WorklistRollupStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == WorklistRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("worklist rollup") \(code)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> WorklistRollup {
            return WorklistRollup(
                code: code,
                title: title,
                acuity: acuity,
                country: country,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a worklist rollup in status new.
    static func newWorklistRollup(_ code: String, title: String) -> WorklistRollup {
        return WorklistRollup(
            code: code,
            title: title,
            acuity: 0,
            country: "",
            name: "",
            status: WorklistRollupStatus.new
        )
    }
}
