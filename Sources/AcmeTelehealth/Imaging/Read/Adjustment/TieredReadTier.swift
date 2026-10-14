import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered read tier is in its life cycle.
    enum TieredReadTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One tiered read tier, with what the planners need to act on it.
    final class TieredReadTier {
        var code: String
        var title: String
        var priority: Int
        var specialty: String
        var amount: Double
        var description: String
        var country: String
        var status: TieredReadTierStatus

        init(code: String, title: String, priority: Int, specialty: String, amount: Double, description: String, country: String, status: TieredReadTierStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.specialty = specialty
            self.amount = amount
            self.description = description
            self.country = country
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

        func canMoveTo(_ next: TieredReadTierStatus) -> Bool {
            switch status {
            case .idle:
                return next == TieredReadTierStatus.draining
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == TieredReadTierStatus.stopped
            case .draining:
                return next == TieredReadTierStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredReadTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered read tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedTotal() -> Double {
            return (amount * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> TieredReadTier {
            return TieredReadTier(
                code: code,
                title: title,
                priority: priority,
                specialty: specialty,
                amount: amount,
                description: description,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered read tier in status idle.
    static func newTieredReadTier(_ code: String, title: String) -> TieredReadTier {
        return TieredReadTier(
            code: code,
            title: title,
            priority: 0,
            specialty: "",
            amount: 0.0,
            description: "",
            country: "",
            status: TieredReadTierStatus.idle
        )
    }
}
