import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance assignment is in its life cycle.
    enum RemittanceAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A remittance assignment. Its code is unique within a tenant.
    final class RemittanceAssignment {
        var code: String
        var name: String
        var allergy: String
        var refills: Int
        var segment: String
        var checksum: String
        var rate: Double
        var status: RemittanceAssignmentStatus

        init(code: String, name: String, allergy: String, refills: Int, segment: String, checksum: String, rate: Double, status: RemittanceAssignmentStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.refills = refills
            self.segment = segment
            self.checksum = checksum
            self.rate = rate
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

        func canMoveTo(_ next: RemittanceAssignmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RemittanceAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("remittance assignment") \(code)"
        }

        func weightedVolume() -> Double {
            return (rate * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceAssignment {
            return RemittanceAssignment(
                code: code,
                name: name,
                allergy: allergy,
                refills: refills,
                segment: segment,
                checksum: checksum,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a remittance assignment in status created.
    static func newRemittanceAssignment(_ code: String, name: String) -> RemittanceAssignment {
        return RemittanceAssignment(
            code: code,
            name: name,
            allergy: "",
            refills: 0,
            segment: "",
            checksum: "",
            rate: 0.0,
            status: RemittanceAssignmentStatus.created
        )
    }
}
