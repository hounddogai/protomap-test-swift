import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense target is in its life cycle.
    enum DispenseTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A dispense target as the dispense team keeps it.
    final class DispenseTarget {
        var code: String
        var label: String
        var attributes: [String: String]
        var ceiling: Double
        var encounterID: String
        var priority: Int
        var status: DispenseTargetStatus

        init(code: String, label: String, attributes: [String: String], ceiling: Double, encounterID: String, priority: Int, status: DispenseTargetStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.priority = priority
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

        func canMoveTo(_ next: DispenseTargetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
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

        func moveTo(_ next: DispenseTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("dispense target") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveValue() -> Double {
            return ((ceiling + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseTarget {
            return DispenseTarget(
                code: code,
                label: label,
                attributes: attributes,
                ceiling: ceiling,
                encounterID: encounterID,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a dispense target in status requested.
    static func newDispenseTarget(_ code: String, label: String) -> DispenseTarget {
        return DispenseTarget(
            code: code,
            label: label,
            attributes: [:],
            ceiling: 0.0,
            encounterID: "",
            priority: 0,
            status: DispenseTargetStatus.requested
        )
    }
}
