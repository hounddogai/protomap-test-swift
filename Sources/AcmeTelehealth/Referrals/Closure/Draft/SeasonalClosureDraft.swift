import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal closure draft is in its life cycle.
    enum SeasonalClosureDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A seasonal closure draft as the closure team keeps it.
    final class SeasonalClosureDraft {
        var code: String
        var title: String
        var active: Bool
        var checksum: String
        var quantity: Int
        var budget: Double
        var status: SeasonalClosureDraftStatus

        init(code: String, title: String, active: Bool, checksum: String, quantity: Int, budget: Double, status: SeasonalClosureDraftStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.checksum = checksum
            self.quantity = quantity
            self.budget = budget
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

        func canMoveTo(_ next: SeasonalClosureDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
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

        func moveTo(_ next: SeasonalClosureDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal closure draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal closure draft") \(code)"
        }

        func projectedValue() -> Double {
            return ((budget - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalClosureDraft {
            return SeasonalClosureDraft(
                code: code,
                title: title,
                active: active,
                checksum: checksum,
                quantity: quantity,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal closure draft in status open.
    static func newSeasonalClosureDraft(_ code: String, title: String) -> SeasonalClosureDraft {
        return SeasonalClosureDraft(
            code: code,
            title: title,
            active: false,
            checksum: "",
            quantity: 0,
            budget: 0.0,
            status: SeasonalClosureDraftStatus.`open`
        )
    }
}
