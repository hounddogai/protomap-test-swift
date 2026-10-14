import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback study slot is in its life cycle.
    enum FallbackStudySlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a fallback study slot and its current status.
    final class FallbackStudySlot {
        var code: String
        var title: String
        var budget: Double
        var currency: String
        var country: String
        var cost: Double
        var active: Bool
        var status: FallbackStudySlotStatus

        init(code: String, title: String, budget: Double, currency: String, country: String, cost: Double, active: Bool, status: FallbackStudySlotStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.currency = currency
            self.country = country
            self.cost = cost
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackStudySlotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FallbackStudySlotStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackStudySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback study slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback study slot") \(code)"
        }

        func weightedTotal() -> Double {
            return ((budget + cost) * 100).rounded() / 100
        }

        func copyValue() -> FallbackStudySlot {
            return FallbackStudySlot(
                code: code,
                title: title,
                budget: budget,
                currency: currency,
                country: country,
                cost: cost,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback study slot in status idle.
    static func newFallbackStudySlot(_ code: String, title: String) -> FallbackStudySlot {
        return FallbackStudySlot(
            code: code,
            title: title,
            budget: 0.0,
            currency: "",
            country: "",
            cost: 0.0,
            active: false,
            status: FallbackStudySlotStatus.idle
        )
    }
}
