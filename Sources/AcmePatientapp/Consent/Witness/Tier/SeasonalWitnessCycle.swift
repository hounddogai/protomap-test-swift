import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal witness cycle is in its life cycle.
    enum SeasonalWitnessCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal witness cycle as the witness team keeps it.
    final class SeasonalWitnessCycle {
        var code: String
        var name: String
        var ratio: Double
        var limit: Int
        var maximum: Double
        var active: Bool
        var ward: String
        var floorValue: Double
        var label: String
        var priority: Int
        var visible: Bool
        var status: SeasonalWitnessCycleStatus

        init(code: String, name: String, ratio: Double, limit: Int, maximum: Double, active: Bool, ward: String, floorValue: Double, label: String, priority: Int, visible: Bool, status: SeasonalWitnessCycleStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.limit = limit
            self.maximum = maximum
            self.active = active
            self.ward = ward
            self.floorValue = floorValue
            self.label = label
            self.priority = priority
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalWitnessCycleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: SeasonalWitnessCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal witness cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return ((floorValue + maximum) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalWitnessCycle {
            return SeasonalWitnessCycle(
                code: code,
                name: name,
                ratio: ratio,
                limit: limit,
                maximum: maximum,
                active: active,
                ward: ward,
                floorValue: floorValue,
                label: label,
                priority: priority,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a seasonal witness cycle in status proposed.
    static func newSeasonalWitnessCycle(_ code: String, name: String) -> SeasonalWitnessCycle {
        return SeasonalWitnessCycle(
            code: code,
            name: name,
            ratio: 0.0,
            limit: 0,
            maximum: 0.0,
            active: false,
            ward: "",
            floorValue: 0.0,
            label: "",
            priority: 0,
            visible: false,
            status: SeasonalWitnessCycleStatus.proposed
        )
    }
}
