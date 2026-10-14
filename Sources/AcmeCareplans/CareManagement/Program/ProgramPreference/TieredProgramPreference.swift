import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered program preference is in its life cycle.
    enum TieredProgramPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered program preference as the program team keeps it.
    final class TieredProgramPreference {
        var code: String
        var name: String
        var ceiling: Double
        var title: String
        var label: String
        var capacity: Int
        var attempts: Int
        var approved: Bool
        var floorValue: Double
        var status: TieredProgramPreferenceStatus

        init(code: String, name: String, ceiling: Double, title: String, label: String, capacity: Int, attempts: Int, approved: Bool, floorValue: Double, status: TieredProgramPreferenceStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.title = title
            self.label = label
            self.capacity = capacity
            self.attempts = attempts
            self.approved = approved
            self.floorValue = floorValue
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

        func canMoveTo(_ next: TieredProgramPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == TieredProgramPreferenceStatus.stopped
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
                switch next {
                case .stopped:
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

        func moveTo(_ next: TieredProgramPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered program preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered program preference") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((ceiling + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> TieredProgramPreference {
            return TieredProgramPreference(
                code: code,
                name: name,
                ceiling: ceiling,
                title: title,
                label: label,
                capacity: capacity,
                attempts: attempts,
                approved: approved,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered program preference in status idle.
    static func newTieredProgramPreference(_ code: String, name: String) -> TieredProgramPreference {
        return TieredProgramPreference(
            code: code,
            name: name,
            ceiling: 0.0,
            title: "",
            label: "",
            capacity: 0,
            attempts: 0,
            approved: false,
            floorValue: 0.0,
            status: TieredProgramPreferenceStatus.idle
        )
    }
}
