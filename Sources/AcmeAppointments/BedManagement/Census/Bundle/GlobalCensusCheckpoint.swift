import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global census checkpoint is in its life cycle.
    enum GlobalCensusCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global census checkpoint. Its code is unique within a tenant.
    final class GlobalCensusCheckpoint {
        var code: String
        var title: String
        var budget: Double
        var unit: String
        var batchSize: Int
        var endsAt: Int
        var status: GlobalCensusCheckpointStatus

        init(code: String, title: String, budget: Double, unit: String, batchSize: Int, endsAt: Int, status: GlobalCensusCheckpointStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.unit = unit
            self.batchSize = batchSize
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalCensusCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalCensusCheckpointStatus.reopened
            case .inReview:
                return next == GlobalCensusCheckpointStatus.resolved || next == GlobalCensusCheckpointStatus.reopened
            case .resolved:
                return next == GlobalCensusCheckpointStatus.reopened || next == GlobalCensusCheckpointStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: GlobalCensusCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global census checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global census checkpoint") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(endsAt) + budget) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCensusCheckpoint {
            return GlobalCensusCheckpoint(
                code: code,
                title: title,
                budget: budget,
                unit: unit,
                batchSize: batchSize,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global census checkpoint in status open.
    static func newGlobalCensusCheckpoint(_ code: String, title: String) -> GlobalCensusCheckpoint {
        return GlobalCensusCheckpoint(
            code: code,
            title: title,
            budget: 0.0,
            unit: "",
            batchSize: 0,
            endsAt: 0,
            status: GlobalCensusCheckpointStatus.`open`
        )
    }
}
