import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall snapshot is in its life cycle.
    enum RecallSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a recall snapshot and its current status.
    final class RecallSnapshot {
        var code: String
        var name: String
        var ownerID: String
        var region: String
        var ratio: Double
        var status: RecallSnapshotStatus

        init(code: String, name: String, ownerID: String, region: String, ratio: Double, status: RecallSnapshotStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.region = region
            self.ratio = ratio
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

        func canMoveTo(_ next: RecallSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RecallSnapshotStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RecallSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> RecallSnapshot {
            return RecallSnapshot(
                code: code,
                name: name,
                ownerID: ownerID,
                region: region,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a recall snapshot in status open.
    static func newRecallSnapshot(_ code: String, name: String) -> RecallSnapshot {
        return RecallSnapshot(
            code: code,
            name: name,
            ownerID: "",
            region: "",
            ratio: 0.0,
            status: RecallSnapshotStatus.`open`
        )
    }
}
