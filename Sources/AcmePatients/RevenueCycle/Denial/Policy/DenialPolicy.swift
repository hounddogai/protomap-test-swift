import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial policy is in its life cycle.
    enum DenialPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a denial policy and its current status.
    final class DenialPolicy {
        var code: String
        var name: String
        var ownerID: String
        var region: String
        var maximum: Double
        var patientRef: String
        var checksum: String
        var capacity: Int
        var status: DenialPolicyStatus

        init(code: String, name: String, ownerID: String, region: String, maximum: Double, patientRef: String, checksum: String, capacity: Int, status: DenialPolicyStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.region = region
            self.maximum = maximum
            self.patientRef = patientRef
            self.checksum = checksum
            self.capacity = capacity
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

        func canMoveTo(_ next: DenialPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DenialPolicyStatus.approved || next == DenialPolicyStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DenialPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedLoad() -> Double {
            return (Double(capacity) * maximum * 100).rounded() / 100
        }

        func copyValue() -> DenialPolicy {
            return DenialPolicy(
                code: code,
                name: name,
                ownerID: ownerID,
                region: region,
                maximum: maximum,
                patientRef: patientRef,
                checksum: checksum,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a denial policy in status proposed.
    static func newDenialPolicy(_ code: String, name: String) -> DenialPolicy {
        return DenialPolicy(
            code: code,
            name: name,
            ownerID: "",
            region: "",
            maximum: 0.0,
            patientRef: "",
            checksum: "",
            capacity: 0,
            status: DenialPolicyStatus.proposed
        )
    }
}
