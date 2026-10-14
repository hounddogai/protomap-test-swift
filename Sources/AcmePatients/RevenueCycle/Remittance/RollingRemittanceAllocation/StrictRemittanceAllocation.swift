import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict remittance allocation is in its life cycle.
    enum StrictRemittanceAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict remittance allocation as the remittance team keeps it.
    final class StrictRemittanceAllocation {
        var code: String
        var name: String
        var priority: Int
        var attributes: [String: String]
        var specialty: String
        var maximum: Double
        var encounterID: String
        var diagnosisCode: String
        var capacity: Int
        var payer: String
        var status: StrictRemittanceAllocationStatus

        init(code: String, name: String, priority: Int, attributes: [String: String], specialty: String, maximum: Double, encounterID: String, diagnosisCode: String, capacity: Int, payer: String, status: StrictRemittanceAllocationStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.attributes = attributes
            self.specialty = specialty
            self.maximum = maximum
            self.encounterID = encounterID
            self.diagnosisCode = diagnosisCode
            self.capacity = capacity
            self.payer = payer
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

        func canMoveTo(_ next: StrictRemittanceAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictRemittanceAllocationStatus.rejected || next == StrictRemittanceAllocationStatus.withdrawn
            case .approved:
                return next == StrictRemittanceAllocationStatus.withdrawn
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

        func moveTo(_ next: StrictRemittanceAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict remittance allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func netValue() -> Double {
            return (Double(priority) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> StrictRemittanceAllocation {
            return StrictRemittanceAllocation(
                code: code,
                name: name,
                priority: priority,
                attributes: attributes,
                specialty: specialty,
                maximum: maximum,
                encounterID: encounterID,
                diagnosisCode: diagnosisCode,
                capacity: capacity,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict remittance allocation in status proposed.
    static func newStrictRemittanceAllocation(_ code: String, name: String) -> StrictRemittanceAllocation {
        return StrictRemittanceAllocation(
            code: code,
            name: name,
            priority: 0,
            attributes: [:],
            specialty: "",
            maximum: 0.0,
            encounterID: "",
            diagnosisCode: "",
            capacity: 0,
            payer: "",
            status: StrictRemittanceAllocationStatus.proposed
        )
    }
}
