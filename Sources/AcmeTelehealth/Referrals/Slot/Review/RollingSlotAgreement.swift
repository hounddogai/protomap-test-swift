import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling slot agreement is in its life cycle.
    enum RollingSlotAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling slot agreement as the slot team keeps it.
    final class RollingSlotAgreement {
        var code: String
        var name: String
        var floorValue: Double
        var batchSize: Int
        var sequence: Int
        var status: RollingSlotAgreementStatus

        init(code: String, name: String, floorValue: Double, batchSize: Int, sequence: Int, status: RollingSlotAgreementStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.batchSize = batchSize
            self.sequence = sequence
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

        func canMoveTo(_ next: RollingSlotAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
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

        func moveTo(_ next: RollingSlotAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling slot agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return (Double(sequence) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> RollingSlotAgreement {
            return RollingSlotAgreement(
                code: code,
                name: name,
                floorValue: floorValue,
                batchSize: batchSize,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling slot agreement in status proposed.
    static func newRollingSlotAgreement(_ code: String, name: String) -> RollingSlotAgreement {
        return RollingSlotAgreement(
            code: code,
            name: name,
            floorValue: 0.0,
            batchSize: 0,
            sequence: 0,
            status: RollingSlotAgreementStatus.proposed
        )
    }
}
