import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default interaction profile is in its life cycle.
    enum DefaultInteractionProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One default interaction profile, with what the planners need to act on it.
    final class DefaultInteractionProfile {
        var code: String
        var name: String
        var visible: Bool
        var windowDays: Int
        var active: Bool
        var floorValue: Double
        var version: Int
        var weight: Double
        var region: String
        var status: DefaultInteractionProfileStatus

        init(code: String, name: String, visible: Bool, windowDays: Int, active: Bool, floorValue: Double, version: Int, weight: Double, region: String, status: DefaultInteractionProfileStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.windowDays = windowDays
            self.active = active
            self.floorValue = floorValue
            self.version = version
            self.weight = weight
            self.region = region
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

        func canMoveTo(_ next: DefaultInteractionProfileStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == DefaultInteractionProfileStatus.published || next == DefaultInteractionProfileStatus.retired
            case .published:
                return next == DefaultInteractionProfileStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultInteractionProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default interaction profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netExposure() -> Double {
            return (Double(version) * weight * 100).rounded() / 100
        }

        func copyValue() -> DefaultInteractionProfile {
            return DefaultInteractionProfile(
                code: code,
                name: name,
                visible: visible,
                windowDays: windowDays,
                active: active,
                floorValue: floorValue,
                version: version,
                weight: weight,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a default interaction profile in status created.
    static func newDefaultInteractionProfile(_ code: String, name: String) -> DefaultInteractionProfile {
        return DefaultInteractionProfile(
            code: code,
            name: name,
            visible: false,
            windowDays: 0,
            active: false,
            floorValue: 0.0,
            version: 0,
            weight: 0.0,
            region: "",
            status: DefaultInteractionProfileStatus.created
        )
    }
}
