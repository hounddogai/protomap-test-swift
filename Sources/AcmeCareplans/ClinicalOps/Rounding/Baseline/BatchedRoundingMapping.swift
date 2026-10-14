import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched rounding mapping is in its life cycle.
    enum BatchedRoundingMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched rounding mapping as the rounding team keeps it.
    final class BatchedRoundingMapping {
        var code: String
        var name: String
        var patientRef: String
        var attributes: [String: String]
        var description: String
        var diagnosisCode: String
        var quantity: Int
        var status: BatchedRoundingMappingStatus

        init(code: String, name: String, patientRef: String, attributes: [String: String], description: String, diagnosisCode: String, quantity: Int, status: BatchedRoundingMappingStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.attributes = attributes
            self.description = description
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
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

        func canMoveTo(_ next: BatchedRoundingMappingStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
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
                return next == BatchedRoundingMappingStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedRoundingMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched rounding mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched rounding mapping") \(code)"
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
            return Double(quantity)
        }

        func copyValue() -> BatchedRoundingMapping {
            return BatchedRoundingMapping(
                code: code,
                name: name,
                patientRef: patientRef,
                attributes: attributes,
                description: description,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched rounding mapping in status proposed.
    static func newBatchedRoundingMapping(_ code: String, name: String) -> BatchedRoundingMapping {
        return BatchedRoundingMapping(
            code: code,
            name: name,
            patientRef: "",
            attributes: [:],
            description: "",
            diagnosisCode: "",
            quantity: 0,
            status: BatchedRoundingMappingStatus.proposed
        )
    }
}
