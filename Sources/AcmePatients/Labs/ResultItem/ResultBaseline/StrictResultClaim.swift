import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict result claim is in its life cycle.
    enum StrictResultClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One strict result claim, with what the planners need to act on it.
    final class StrictResultClaim {
        var code: String
        var name: String
        var copay: Double
        var ownerID: String
        var windowDays: Int
        var reviewer: String
        var floorValue: Double
        var batchSize: Int
        var summary: String
        var score: Double
        var status: StrictResultClaimStatus

        init(code: String, name: String, copay: Double, ownerID: String, windowDays: Int, reviewer: String, floorValue: Double, batchSize: Int, summary: String, score: Double, status: StrictResultClaimStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.ownerID = ownerID
            self.windowDays = windowDays
            self.reviewer = reviewer
            self.floorValue = floorValue
            self.batchSize = batchSize
            self.summary = summary
            self.score = score
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

        func canMoveTo(_ next: StrictResultClaimStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == StrictResultClaimStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == StrictResultClaimStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictResultClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict result claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedTotal() -> Double {
            return ((floorValue - copay) * 100).rounded() / 100
        }

        func copyValue() -> StrictResultClaim {
            return StrictResultClaim(
                code: code,
                name: name,
                copay: copay,
                ownerID: ownerID,
                windowDays: windowDays,
                reviewer: reviewer,
                floorValue: floorValue,
                batchSize: batchSize,
                summary: summary,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict result claim in status open.
    static func newStrictResultClaim(_ code: String, name: String) -> StrictResultClaim {
        return StrictResultClaim(
            code: code,
            name: name,
            copay: 0.0,
            ownerID: "",
            windowDays: 0,
            reviewer: "",
            floorValue: 0.0,
            batchSize: 0,
            summary: "",
            score: 0.0,
            status: StrictResultClaimStatus.`open`
        )
    }
}
