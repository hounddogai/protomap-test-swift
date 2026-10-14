import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback dispense mapping is in its life cycle.
    enum FallbackDispenseMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback dispense mapping as the dispense team keeps it.
    final class FallbackDispenseMapping {
        var code: String
        var label: String
        var ownerID: String
        var region: String
        var attributes: [String: String]
        var description: String
        var maximum: Double
        var unit: String
        var status: FallbackDispenseMappingStatus

        init(code: String, label: String, ownerID: String, region: String, attributes: [String: String], description: String, maximum: Double, unit: String, status: FallbackDispenseMappingStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.region = region
            self.attributes = attributes
            self.description = description
            self.maximum = maximum
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

        func canMoveTo(_ next: FallbackDispenseMappingStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackDispenseMappingStatus.ready
            case .warming:
                return next == FallbackDispenseMappingStatus.draining || next == FallbackDispenseMappingStatus.stopped
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

        func moveTo(_ next: FallbackDispenseMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback dispense mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> FallbackDispenseMapping {
            return FallbackDispenseMapping(
                code: code,
                label: label,
                ownerID: ownerID,
                region: region,
                attributes: attributes,
                description: description,
                maximum: maximum,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback dispense mapping in status idle.
    static func newFallbackDispenseMapping(_ code: String, label: String) -> FallbackDispenseMapping {
        return FallbackDispenseMapping(
            code: code,
            label: label,
            ownerID: "",
            region: "",
            attributes: [:],
            description: "",
            maximum: 0.0,
            unit: "",
            status: FallbackDispenseMappingStatus.idle
        )
    }
}
