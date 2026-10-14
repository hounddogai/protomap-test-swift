import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary interaction allocation is in its life cycle.
    enum PrimaryInteractionAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary interaction allocation. Its code is unique within a tenant.
    final class PrimaryInteractionAllocation {
        var code: String
        var label: String
        var startsAt: Int
        var weight: Double
        var checksum: String
        var status: PrimaryInteractionAllocationStatus

        init(code: String, label: String, startsAt: Int, weight: Double, checksum: String, status: PrimaryInteractionAllocationStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.weight = weight
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

        func canMoveTo(_ next: PrimaryInteractionAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryInteractionAllocationStatus.approved || next == PrimaryInteractionAllocationStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PrimaryInteractionAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary interaction allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("primary interaction allocation") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(startsAt) * weight * 100).rounded() / 100
        }

        func copyValue() -> PrimaryInteractionAllocation {
            return PrimaryInteractionAllocation(
                code: code,
                label: label,
                startsAt: startsAt,
                weight: weight,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary interaction allocation in status proposed.
    static func newPrimaryInteractionAllocation(_ code: String, label: String) -> PrimaryInteractionAllocation {
        return PrimaryInteractionAllocation(
            code: code,
            label: label,
            startsAt: 0,
            weight: 0.0,
            checksum: "",
            status: PrimaryInteractionAllocationStatus.proposed
        )
    }
}
