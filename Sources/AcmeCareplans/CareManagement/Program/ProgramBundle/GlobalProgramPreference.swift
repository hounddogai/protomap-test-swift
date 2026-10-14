import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global program preference is in its life cycle.
    enum GlobalProgramPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One global program preference, with what the planners need to act on it.
    final class GlobalProgramPreference {
        var code: String
        var title: String
        var country: String
        var capacity: Int
        var attributes: [String: String]
        var rate: Double
        var minimum: Double
        var externalRef: String
        var unit: String
        var status: GlobalProgramPreferenceStatus

        init(code: String, title: String, country: String, capacity: Int, attributes: [String: String], rate: Double, minimum: Double, externalRef: String, unit: String, status: GlobalProgramPreferenceStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.capacity = capacity
            self.attributes = attributes
            self.rate = rate
            self.minimum = minimum
            self.externalRef = externalRef
            self.unit = unit
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

        func canMoveTo(_ next: GlobalProgramPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == GlobalProgramPreferenceStatus.draining
            case .ready:
                return next == GlobalProgramPreferenceStatus.draining
            case .draining:
                return next == GlobalProgramPreferenceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalProgramPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global program preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
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

        func projectedLoad() -> Double {
            return (Double(capacity) * rate * 100).rounded() / 100
        }

        func copyValue() -> GlobalProgramPreference {
            return GlobalProgramPreference(
                code: code,
                title: title,
                country: country,
                capacity: capacity,
                attributes: attributes,
                rate: rate,
                minimum: minimum,
                externalRef: externalRef,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a global program preference in status idle.
    static func newGlobalProgramPreference(_ code: String, title: String) -> GlobalProgramPreference {
        return GlobalProgramPreference(
            code: code,
            title: title,
            country: "",
            capacity: 0,
            attributes: [:],
            rate: 0.0,
            minimum: 0.0,
            externalRef: "",
            unit: "",
            status: GlobalProgramPreferenceStatus.idle
        )
    }
}
