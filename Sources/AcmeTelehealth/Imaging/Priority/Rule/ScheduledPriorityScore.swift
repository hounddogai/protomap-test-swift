import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled priority score is in its life cycle.
    enum ScheduledPriorityScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One scheduled priority score, with what the planners need to act on it.
    final class ScheduledPriorityScore {
        var code: String
        var label: String
        var createdAt: Int
        var cost: Double
        var title: String
        var visitMinutes: Int
        var weight: Double
        var summary: String
        var pinned: Bool
        var acuity: Int
        var status: ScheduledPriorityScoreStatus

        init(code: String, label: String, createdAt: Int, cost: Double, title: String, visitMinutes: Int, weight: Double, summary: String, pinned: Bool, acuity: Int, status: ScheduledPriorityScoreStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.cost = cost
            self.title = title
            self.visitMinutes = visitMinutes
            self.weight = weight
            self.summary = summary
            self.pinned = pinned
            self.acuity = acuity
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

        func canMoveTo(_ next: ScheduledPriorityScoreStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledPriorityScoreStatus.validated || next == ScheduledPriorityScoreStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ScheduledPriorityScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled priority score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("scheduled priority score") \(code)"
        }

        func netValue() -> Double {
            return (cost * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledPriorityScore {
            return ScheduledPriorityScore(
                code: code,
                label: label,
                createdAt: createdAt,
                cost: cost,
                title: title,
                visitMinutes: visitMinutes,
                weight: weight,
                summary: summary,
                pinned: pinned,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled priority score in status created.
    static func newScheduledPriorityScore(_ code: String, label: String) -> ScheduledPriorityScore {
        return ScheduledPriorityScore(
            code: code,
            label: label,
            createdAt: 0,
            cost: 0.0,
            title: "",
            visitMinutes: 0,
            weight: 0.0,
            summary: "",
            pinned: false,
            acuity: 0,
            status: ScheduledPriorityScoreStatus.created
        )
    }
}
