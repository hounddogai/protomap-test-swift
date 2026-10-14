import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual read plan is in its life cycle.
    enum ManualReadPlanStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One manual read plan, with what the planners need to act on it.
    final class ManualReadPlan {
        var code: String
        var name: String
        var reviewer: String
        var ownerID: String
        var limit: Int
        var updatedAt: Int
        var windowDays: Int
        var batchSize: Int
        var status: ManualReadPlanStatus

        init(code: String, name: String, reviewer: String, ownerID: String, limit: Int, updatedAt: Int, windowDays: Int, batchSize: Int, status: ManualReadPlanStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.ownerID = ownerID
            self.limit = limit
            self.updatedAt = updatedAt
            self.windowDays = windowDays
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualReadPlanStatus) -> Bool {
            switch status {
            case .created:
                return next == ManualReadPlanStatus.published || next == ManualReadPlanStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ManualReadPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual read plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedTotal() -> Double {
            return (Double(limit) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> ManualReadPlan {
            return ManualReadPlan(
                code: code,
                name: name,
                reviewer: reviewer,
                ownerID: ownerID,
                limit: limit,
                updatedAt: updatedAt,
                windowDays: windowDays,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual read plan in status created.
    static func newManualReadPlan(_ code: String, name: String) -> ManualReadPlan {
        return ManualReadPlan(
            code: code,
            name: name,
            reviewer: "",
            ownerID: "",
            limit: 0,
            updatedAt: 0,
            windowDays: 0,
            batchSize: 0,
            status: ManualReadPlanStatus.created
        )
    }
}
