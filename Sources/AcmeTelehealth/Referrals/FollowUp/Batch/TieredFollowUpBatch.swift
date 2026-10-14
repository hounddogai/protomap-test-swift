import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered follow up batch is in its life cycle.
    enum TieredFollowUpBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a tiered follow up batch and its current status.
    final class TieredFollowUpBatch {
        var code: String
        var title: String
        var patientRef: String
        var floorValue: Double
        var batchSize: Int
        var minimum: Double
        var tags: [String]
        var status: TieredFollowUpBatchStatus

        init(code: String, title: String, patientRef: String, floorValue: Double, batchSize: Int, minimum: Double, tags: [String], status: TieredFollowUpBatchStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.floorValue = floorValue
            self.batchSize = batchSize
            self.minimum = minimum
            self.tags = tags
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

        func canMoveTo(_ next: TieredFollowUpBatchStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: TieredFollowUpBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered follow up batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return ((minimum - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> TieredFollowUpBatch {
            return TieredFollowUpBatch(
                code: code,
                title: title,
                patientRef: patientRef,
                floorValue: floorValue,
                batchSize: batchSize,
                minimum: minimum,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered follow up batch in status open.
    static func newTieredFollowUpBatch(_ code: String, title: String) -> TieredFollowUpBatch {
        return TieredFollowUpBatch(
            code: code,
            title: title,
            patientRef: "",
            floorValue: 0.0,
            batchSize: 0,
            minimum: 0.0,
            tags: [],
            status: TieredFollowUpBatchStatus.`open`
        )
    }
}
