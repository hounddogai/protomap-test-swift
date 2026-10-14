import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered formulary rollup is in its life cycle.
    enum TieredFormularyRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One tiered formulary rollup, with what the planners need to act on it.
    final class TieredFormularyRollup {
        var code: String
        var name: String
        var country: String
        var ratio: Double
        var amount: Double
        var createdAt: Int
        var ownerID: String
        var status: TieredFormularyRollupStatus

        init(code: String, name: String, country: String, ratio: Double, amount: Double, createdAt: Int, ownerID: String, status: TieredFormularyRollupStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.ratio = ratio
            self.amount = amount
            self.createdAt = createdAt
            self.ownerID = ownerID
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

        func canMoveTo(_ next: TieredFormularyRollupStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredFormularyRollupStatus.completed
            case .scheduled:
                return next == TieredFormularyRollupStatus.inProgress || next == TieredFormularyRollupStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == TieredFormularyRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredFormularyRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered formulary rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netValue() -> Double {
            return ((ratio - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredFormularyRollup {
            return TieredFormularyRollup(
                code: code,
                name: name,
                country: country,
                ratio: ratio,
                amount: amount,
                createdAt: createdAt,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered formulary rollup in status planned.
    static func newTieredFormularyRollup(_ code: String, name: String) -> TieredFormularyRollup {
        return TieredFormularyRollup(
            code: code,
            name: name,
            country: "",
            ratio: 0.0,
            amount: 0.0,
            createdAt: 0,
            ownerID: "",
            status: TieredFormularyRollupStatus.planned
        )
    }
}
