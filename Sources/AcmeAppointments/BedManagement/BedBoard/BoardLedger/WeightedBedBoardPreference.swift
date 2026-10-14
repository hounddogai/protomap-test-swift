import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted bed board preference is in its life cycle.
    enum WeightedBedBoardPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted bed board preference. Its code is unique within a tenant.
    final class WeightedBedBoardPreference {
        var code: String
        var title: String
        var cost: Double
        var active: Bool
        var score: Double
        var batchSize: Int
        var pinned: Bool
        var floorValue: Double
        var status: WeightedBedBoardPreferenceStatus

        init(code: String, title: String, cost: Double, active: Bool, score: Double, batchSize: Int, pinned: Bool, floorValue: Double, status: WeightedBedBoardPreferenceStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.active = active
            self.score = score
            self.batchSize = batchSize
            self.pinned = pinned
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedBedBoardPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedBedBoardPreferenceStatus.active
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == WeightedBedBoardPreferenceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedBedBoardPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted bed board preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedValue() -> Double {
            return ((cost - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedBedBoardPreference {
            return WeightedBedBoardPreference(
                code: code,
                title: title,
                cost: cost,
                active: active,
                score: score,
                batchSize: batchSize,
                pinned: pinned,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted bed board preference in status draft.
    static func newWeightedBedBoardPreference(_ code: String, title: String) -> WeightedBedBoardPreference {
        return WeightedBedBoardPreference(
            code: code,
            title: title,
            cost: 0.0,
            active: false,
            score: 0.0,
            batchSize: 0,
            pinned: false,
            floorValue: 0.0,
            status: WeightedBedBoardPreferenceStatus.draft
        )
    }
}
