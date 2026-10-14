import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted outreach allocation is in its life cycle.
    enum WeightedOutreachAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted outreach allocation as the outreach team keeps it.
    final class WeightedOutreachAllocation {
        var code: String
        var name: String
        var version: Int
        var batchSize: Int
        var patientRef: String
        var segment: String
        var status: WeightedOutreachAllocationStatus

        init(code: String, name: String, version: Int, batchSize: Int, patientRef: String, segment: String, status: WeightedOutreachAllocationStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.batchSize = batchSize
            self.patientRef = patientRef
            self.segment = segment
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

        func canMoveTo(_ next: WeightedOutreachAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == WeightedOutreachAllocationStatus.rejected || next == WeightedOutreachAllocationStatus.withdrawn
            case .rejected:
                return next == WeightedOutreachAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedOutreachAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted outreach allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return ((Double(batchSize) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedOutreachAllocation {
            return WeightedOutreachAllocation(
                code: code,
                name: name,
                version: version,
                batchSize: batchSize,
                patientRef: patientRef,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a weighted outreach allocation in status proposed.
    static func newWeightedOutreachAllocation(_ code: String, name: String) -> WeightedOutreachAllocation {
        return WeightedOutreachAllocation(
            code: code,
            name: name,
            version: 0,
            batchSize: 0,
            patientRef: "",
            segment: "",
            status: WeightedOutreachAllocationStatus.proposed
        )
    }
}
