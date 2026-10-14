import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped statement rollup is in its life cycle.
    enum CappedStatementRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One capped statement rollup, with what the planners need to act on it.
    final class CappedStatementRollup {
        var code: String
        var name: String
        var copay: Double
        var budget: Double
        var bed: String
        var minimum: Double
        var floorValue: Double
        var status: CappedStatementRollupStatus

        init(code: String, name: String, copay: Double, budget: Double, bed: String, minimum: Double, floorValue: Double, status: CappedStatementRollupStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.budget = budget
            self.bed = bed
            self.minimum = minimum
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedStatementRollupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CappedStatementRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped statement rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return (copay * budget * 100).rounded() / 100
        }

        func copyValue() -> CappedStatementRollup {
            return CappedStatementRollup(
                code: code,
                name: name,
                copay: copay,
                budget: budget,
                bed: bed,
                minimum: minimum,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped statement rollup in status requested.
    static func newCappedStatementRollup(_ code: String, name: String) -> CappedStatementRollup {
        return CappedStatementRollup(
            code: code,
            name: name,
            copay: 0.0,
            budget: 0.0,
            bed: "",
            minimum: 0.0,
            floorValue: 0.0,
            status: CappedStatementRollupStatus.requested
        )
    }
}
