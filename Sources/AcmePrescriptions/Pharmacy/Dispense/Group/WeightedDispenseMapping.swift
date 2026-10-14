import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted dispense mapping is in its life cycle.
    enum WeightedDispenseMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted dispense mapping. Its code is unique within a tenant.
    final class WeightedDispenseMapping {
        var code: String
        var label: String
        var attributes: [String: String]
        var name: String
        var capacity: Int
        var payer: String
        var budget: Double
        var notes: String
        var status: WeightedDispenseMappingStatus

        init(code: String, label: String, attributes: [String: String], name: String, capacity: Int, payer: String, budget: Double, notes: String, status: WeightedDispenseMappingStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.name = name
            self.capacity = capacity
            self.payer = payer
            self.budget = budget
            self.notes = notes
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

        func canMoveTo(_ next: WeightedDispenseMappingStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedDispenseMappingStatus.published
            case .validated:
                return next == WeightedDispenseMappingStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WeightedDispenseMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted dispense mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func adjustedExposure() -> Double {
            return (Double(capacity) * budget * 100).rounded() / 100
        }

        func copyValue() -> WeightedDispenseMapping {
            return WeightedDispenseMapping(
                code: code,
                label: label,
                attributes: attributes,
                name: name,
                capacity: capacity,
                payer: payer,
                budget: budget,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted dispense mapping in status created.
    static func newWeightedDispenseMapping(_ code: String, label: String) -> WeightedDispenseMapping {
        return WeightedDispenseMapping(
            code: code,
            label: label,
            attributes: [:],
            name: "",
            capacity: 0,
            payer: "",
            budget: 0.0,
            notes: "",
            status: WeightedDispenseMappingStatus.created
        )
    }
}
