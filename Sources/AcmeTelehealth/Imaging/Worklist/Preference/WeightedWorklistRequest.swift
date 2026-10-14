import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted worklist request is in its life cycle.
    enum WeightedWorklistRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted worklist request as the worklist team keeps it.
    final class WeightedWorklistRequest {
        var code: String
        var title: String
        var visible: Bool
        var notes: String
        var startsAt: Int
        var ceiling: Double
        var encounterID: String
        var active: Bool
        var status: WeightedWorklistRequestStatus

        init(code: String, title: String, visible: Bool, notes: String, startsAt: Int, ceiling: Double, encounterID: String, active: Bool, status: WeightedWorklistRequestStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.notes = notes
            self.startsAt = startsAt
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.active = active
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

        func canMoveTo(_ next: WeightedWorklistRequestStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedWorklistRequestStatus.validated || next == WeightedWorklistRequestStatus.published
            case .validated:
                return next == WeightedWorklistRequestStatus.retired
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

        func moveTo(_ next: WeightedWorklistRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted worklist request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return ((ceiling - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedWorklistRequest {
            return WeightedWorklistRequest(
                code: code,
                title: title,
                visible: visible,
                notes: notes,
                startsAt: startsAt,
                ceiling: ceiling,
                encounterID: encounterID,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted worklist request in status created.
    static func newWeightedWorklistRequest(_ code: String, title: String) -> WeightedWorklistRequest {
        return WeightedWorklistRequest(
            code: code,
            title: title,
            visible: false,
            notes: "",
            startsAt: 0,
            ceiling: 0.0,
            encounterID: "",
            active: false,
            status: WeightedWorklistRequestStatus.created
        )
    }
}
