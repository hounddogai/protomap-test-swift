import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning policy is in its life cycle.
    enum CleaningPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A cleaning policy. Its code is unique within a tenant.
    final class CleaningPolicy {
        var code: String
        var label: String
        var rate: Double
        var timezone: String
        var ownerID: String
        var sequence: Int
        var ceiling: Double
        var ratio: Double
        var version: Int
        var phone: String
        var status: CleaningPolicyStatus

        init(code: String, label: String, rate: Double, timezone: String, ownerID: String, sequence: Int, ceiling: Double, ratio: Double, version: Int, phone: String, status: CleaningPolicyStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.timezone = timezone
            self.ownerID = ownerID
            self.sequence = sequence
            self.ceiling = ceiling
            self.ratio = ratio
            self.version = version
            self.phone = phone
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

        func canMoveTo(_ next: CleaningPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CleaningPolicyStatus.rejected || next == CleaningPolicyStatus.withdrawn
            case .rejected:
                return next == CleaningPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("cleaning policy") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(version) - rate) * 100).rounded() / 100
        }

        func copyValue() -> CleaningPolicy {
            return CleaningPolicy(
                code: code,
                label: label,
                rate: rate,
                timezone: timezone,
                ownerID: ownerID,
                sequence: sequence,
                ceiling: ceiling,
                ratio: ratio,
                version: version,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a cleaning policy in status proposed.
    static func newCleaningPolicy(_ code: String, label: String) -> CleaningPolicy {
        return CleaningPolicy(
            code: code,
            label: label,
            rate: 0.0,
            timezone: "",
            ownerID: "",
            sequence: 0,
            ceiling: 0.0,
            ratio: 0.0,
            version: 0,
            phone: "",
            status: CleaningPolicyStatus.proposed
        )
    }
}
