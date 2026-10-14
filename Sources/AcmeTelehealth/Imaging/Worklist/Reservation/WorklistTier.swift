import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist tier is in its life cycle.
    enum WorklistTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One worklist tier, with what the planners need to act on it.
    final class WorklistTier {
        var code: String
        var name: String
        var cost: Double
        var unit: String
        var batchSize: Int
        var approved: Bool
        var description: String
        var status: WorklistTierStatus

        init(code: String, name: String, cost: Double, unit: String, batchSize: Int, approved: Bool, description: String, status: WorklistTierStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.unit = unit
            self.batchSize = batchSize
            self.approved = approved
            self.description = description
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

        func canMoveTo(_ next: WorklistTierStatus) -> Bool {
            switch status {
            case .new:
                return next == WorklistTierStatus.queued || next == WorklistTierStatus.done
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == WorklistTierStatus.done || next == WorklistTierStatus.failed
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

        func moveTo(_ next: WorklistTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("worklist tier") \(code)"
        }

        func netLoad() -> Double {
            return ((cost - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistTier {
            return WorklistTier(
                code: code,
                name: name,
                cost: cost,
                unit: unit,
                batchSize: batchSize,
                approved: approved,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a worklist tier in status new.
    static func newWorklistTier(_ code: String, name: String) -> WorklistTier {
        return WorklistTier(
            code: code,
            name: name,
            cost: 0.0,
            unit: "",
            batchSize: 0,
            approved: false,
            description: "",
            status: WorklistTierStatus.new
        )
    }
}
