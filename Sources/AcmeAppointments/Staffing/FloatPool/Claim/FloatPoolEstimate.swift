import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool estimate is in its life cycle.
    enum FloatPoolEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A float pool estimate as the float pool team keeps it.
    final class FloatPoolEstimate {
        var code: String
        var name: String
        var archived: Bool
        var capacity: Int
        var summary: String
        var revision: Int
        var status: FloatPoolEstimateStatus

        init(code: String, name: String, archived: Bool, capacity: Int, summary: String, revision: Int, status: FloatPoolEstimateStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.capacity = capacity
            self.summary = summary
            self.revision = revision
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

        func canMoveTo(_ next: FloatPoolEstimateStatus) -> Bool {
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
                return next == FloatPoolEstimateStatus.running
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FloatPoolEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("float pool estimate") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(revision) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolEstimate {
            return FloatPoolEstimate(
                code: code,
                name: name,
                archived: archived,
                capacity: capacity,
                summary: summary,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a float pool estimate in status new.
    static func newFloatPoolEstimate(_ code: String, name: String) -> FloatPoolEstimate {
        return FloatPoolEstimate(
            code: code,
            name: name,
            archived: false,
            capacity: 0,
            summary: "",
            revision: 0,
            status: FloatPoolEstimateStatus.new
        )
    }
}
