import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending program estimate is in its life cycle.
    enum PendingProgramEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One pending program estimate, with what the planners need to act on it.
    final class PendingProgramEstimate {
        var code: String
        var name: String
        var updatedAt: Int
        var ceiling: Double
        var title: String
        var graceDays: Int
        var status: PendingProgramEstimateStatus

        init(code: String, name: String, updatedAt: Int, ceiling: Double, title: String, graceDays: Int, status: PendingProgramEstimateStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.title = title
            self.graceDays = graceDays
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

        func canMoveTo(_ next: PendingProgramEstimateStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingProgramEstimateStatus.warming
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PendingProgramEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending program estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending program estimate") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(graceDays) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingProgramEstimate {
            return PendingProgramEstimate(
                code: code,
                name: name,
                updatedAt: updatedAt,
                ceiling: ceiling,
                title: title,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending program estimate in status idle.
    static func newPendingProgramEstimate(_ code: String, name: String) -> PendingProgramEstimate {
        return PendingProgramEstimate(
            code: code,
            name: name,
            updatedAt: 0,
            ceiling: 0.0,
            title: "",
            graceDays: 0,
            status: PendingProgramEstimateStatus.idle
        )
    }
}
