import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel review is in its life cycle.
    enum PanelReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One panel review, with what the planners need to act on it.
    final class PanelReview {
        var code: String
        var label: String
        var graceDays: Int
        var encounterID: String
        var ownerID: String
        var margin: Double
        var status: PanelReviewStatus

        init(code: String, label: String, graceDays: Int, encounterID: String, ownerID: String, margin: Double, status: PanelReviewStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.margin = margin
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

        func canMoveTo(_ next: PanelReviewStatus) -> Bool {
            switch status {
            case .created:
                return next == PanelReviewStatus.validated || next == PanelReviewStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PanelReviewStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((Double(graceDays) - margin) * 100).rounded() / 100
        }

        func copyValue() -> PanelReview {
            return PanelReview(
                code: code,
                label: label,
                graceDays: graceDays,
                encounterID: encounterID,
                ownerID: ownerID,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel review in status created.
    static func newPanelReview(_ code: String, label: String) -> PanelReview {
        return PanelReview(
            code: code,
            label: label,
            graceDays: 0,
            encounterID: "",
            ownerID: "",
            margin: 0.0,
            status: PanelReviewStatus.created
        )
    }
}
