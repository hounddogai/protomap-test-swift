import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted risk score template is in its life cycle.
    enum WeightedRiskScoreTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One weighted risk score template, with what the planners need to act on it.
    final class WeightedRiskScoreTemplate {
        var code: String
        var name: String
        var channel: String
        var title: String
        var allergy: String
        var startsAt: Int
        var expiresAt: Int
        var budget: Double
        var status: WeightedRiskScoreTemplateStatus

        init(code: String, name: String, channel: String, title: String, allergy: String, startsAt: Int, expiresAt: Int, budget: Double, status: WeightedRiskScoreTemplateStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.title = title
            self.allergy = allergy
            self.startsAt = startsAt
            self.expiresAt = expiresAt
            self.budget = budget
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

        func canMoveTo(_ next: WeightedRiskScoreTemplateStatus) -> Bool {
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
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == WeightedRiskScoreTemplateStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: WeightedRiskScoreTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted risk score template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted risk score template") \(code)"
        }

        func weightedTotal() -> Double {
            return ((budget - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedRiskScoreTemplate {
            return WeightedRiskScoreTemplate(
                code: code,
                name: name,
                channel: channel,
                title: title,
                allergy: allergy,
                startsAt: startsAt,
                expiresAt: expiresAt,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted risk score template in status planned.
    static func newWeightedRiskScoreTemplate(_ code: String, name: String) -> WeightedRiskScoreTemplate {
        return WeightedRiskScoreTemplate(
            code: code,
            name: name,
            channel: "",
            title: "",
            allergy: "",
            startsAt: 0,
            expiresAt: 0,
            budget: 0.0,
            status: WeightedRiskScoreTemplateStatus.planned
        )
    }
}
