import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped risk score window is in its life cycle.
    enum CappedRiskScoreWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One capped risk score window, with what the planners need to act on it.
    final class CappedRiskScoreWindow {
        var code: String
        var title: String
        var description: String
        var endsAt: Int
        var amount: Double
        var ratio: Double
        var currency: String
        var budget: Double
        var visitMinutes: Int
        var active: Bool
        var sequence: Int
        var status: CappedRiskScoreWindowStatus

        init(code: String, title: String, description: String, endsAt: Int, amount: Double, ratio: Double, currency: String, budget: Double, visitMinutes: Int, active: Bool, sequence: Int, status: CappedRiskScoreWindowStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.endsAt = endsAt
            self.amount = amount
            self.ratio = ratio
            self.currency = currency
            self.budget = budget
            self.visitMinutes = visitMinutes
            self.active = active
            self.sequence = sequence
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

        func canMoveTo(_ next: CappedRiskScoreWindowStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedRiskScoreWindowStatus.reopened
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

        func moveTo(_ next: CappedRiskScoreWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped risk score window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return ((amount + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> CappedRiskScoreWindow {
            return CappedRiskScoreWindow(
                code: code,
                title: title,
                description: description,
                endsAt: endsAt,
                amount: amount,
                ratio: ratio,
                currency: currency,
                budget: budget,
                visitMinutes: visitMinutes,
                active: active,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped risk score window in status open.
    static func newCappedRiskScoreWindow(_ code: String, title: String) -> CappedRiskScoreWindow {
        return CappedRiskScoreWindow(
            code: code,
            title: title,
            description: "",
            endsAt: 0,
            amount: 0.0,
            ratio: 0.0,
            currency: "",
            budget: 0.0,
            visitMinutes: 0,
            active: false,
            sequence: 0,
            status: CappedRiskScoreWindowStatus.`open`
        )
    }
}
