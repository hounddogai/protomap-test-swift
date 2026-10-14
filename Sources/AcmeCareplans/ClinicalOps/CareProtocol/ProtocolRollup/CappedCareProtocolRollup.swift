import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped care protocol rollup is in its life cycle.
    enum CappedCareProtocolRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A capped care protocol rollup. Its code is unique within a tenant.
    final class CappedCareProtocolRollup {
        var code: String
        var name: String
        var maximum: Double
        var createdAt: Int
        var floorValue: Double
        var score: Double
        var encounterID: String
        var threshold: Double
        var status: CappedCareProtocolRollupStatus

        init(code: String, name: String, maximum: Double, createdAt: Int, floorValue: Double, score: Double, encounterID: String, threshold: Double, status: CappedCareProtocolRollupStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.createdAt = createdAt
            self.floorValue = floorValue
            self.score = score
            self.encounterID = encounterID
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedCareProtocolRollupStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CappedCareProtocolRollupStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CappedCareProtocolRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCareProtocolRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care protocol rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedLoad() -> Double {
            return ((threshold + score) * 100).rounded() / 100
        }

        func copyValue() -> CappedCareProtocolRollup {
            return CappedCareProtocolRollup(
                code: code,
                name: name,
                maximum: maximum,
                createdAt: createdAt,
                floorValue: floorValue,
                score: score,
                encounterID: encounterID,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped care protocol rollup in status planned.
    static func newCappedCareProtocolRollup(_ code: String, name: String) -> CappedCareProtocolRollup {
        return CappedCareProtocolRollup(
            code: code,
            name: name,
            maximum: 0.0,
            createdAt: 0,
            floorValue: 0.0,
            score: 0.0,
            encounterID: "",
            threshold: 0.0,
            status: CappedCareProtocolRollupStatus.planned
        )
    }
}
