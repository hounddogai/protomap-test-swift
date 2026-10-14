import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board request is in its life cycle.
    enum BedBoardRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a bed board request and its current status.
    final class BedBoardRequest {
        var code: String
        var name: String
        var weight: Double
        var limit: Int
        var region: String
        var status: BedBoardRequestStatus

        init(code: String, name: String, weight: Double, limit: Int, region: String, status: BedBoardRequestStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.limit = limit
            self.region = region
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

        func canMoveTo(_ next: BedBoardRequestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == BedBoardRequestStatus.completed
            case .completed:
                return next == BedBoardRequestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return (Double(limit) * weight * 100).rounded() / 100
        }

        func copyValue() -> BedBoardRequest {
            return BedBoardRequest(
                code: code,
                name: name,
                weight: weight,
                limit: limit,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a bed board request in status planned.
    static func newBedBoardRequest(_ code: String, name: String) -> BedBoardRequest {
        return BedBoardRequest(
            code: code,
            name: name,
            weight: 0.0,
            limit: 0,
            region: "",
            status: BedBoardRequestStatus.planned
        )
    }
}
