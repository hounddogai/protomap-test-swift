import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form mapping is in its life cycle.
    enum ConsentFormMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a consent form mapping and its current status.
    final class ConsentFormMapping {
        var code: String
        var label: String
        var amount: Double
        var description: String
        var capacity: Int
        var acuity: Int
        var checksum: String
        var status: ConsentFormMappingStatus

        init(code: String, label: String, amount: Double, description: String, capacity: Int, acuity: Int, checksum: String, status: ConsentFormMappingStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.description = description
            self.capacity = capacity
            self.acuity = acuity
            self.checksum = checksum
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

        func canMoveTo(_ next: ConsentFormMappingStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ConsentFormMappingStatus.approved
            case .approved:
                return next == ConsentFormMappingStatus.withdrawn
            case .rejected:
                return next == ConsentFormMappingStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netVolume() -> Double {
            return (Double(capacity) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormMapping {
            return ConsentFormMapping(
                code: code,
                label: label,
                amount: amount,
                description: description,
                capacity: capacity,
                acuity: acuity,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a consent form mapping in status proposed.
    static func newConsentFormMapping(_ code: String, label: String) -> ConsentFormMapping {
        return ConsentFormMapping(
            code: code,
            label: label,
            amount: 0.0,
            description: "",
            capacity: 0,
            acuity: 0,
            checksum: "",
            status: ConsentFormMappingStatus.proposed
        )
    }
}
