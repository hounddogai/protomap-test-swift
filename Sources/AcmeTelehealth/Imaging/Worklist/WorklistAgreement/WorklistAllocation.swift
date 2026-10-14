import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist allocation is in its life cycle.
    enum WorklistAllocationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A worklist allocation as the worklist team keeps it.
    final class WorklistAllocation {
        var code: String
        var name: String
        var patientRef: String
        var region: String
        var quantity: Int
        var encounterID: String
        var cost: Double
        var clinicianID: String
        var expiresAt: Int
        var limit: Int
        var visible: Bool
        var status: WorklistAllocationStatus

        init(code: String, name: String, patientRef: String, region: String, quantity: Int, encounterID: String, cost: Double, clinicianID: String, expiresAt: Int, limit: Int, visible: Bool, status: WorklistAllocationStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.region = region
            self.quantity = quantity
            self.encounterID = encounterID
            self.cost = cost
            self.clinicianID = clinicianID
            self.expiresAt = expiresAt
            self.limit = limit
            self.visible = visible
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

        func canMoveTo(_ next: WorklistAllocationStatus) -> Bool {
            switch status {
            case .created:
                return next == WorklistAllocationStatus.published
            case .validated:
                return next == WorklistAllocationStatus.published || next == WorklistAllocationStatus.retired
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

        func moveTo(_ next: WorklistAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) - cost) * 100).rounded() / 100
        }

        func copyValue() -> WorklistAllocation {
            return WorklistAllocation(
                code: code,
                name: name,
                patientRef: patientRef,
                region: region,
                quantity: quantity,
                encounterID: encounterID,
                cost: cost,
                clinicianID: clinicianID,
                expiresAt: expiresAt,
                limit: limit,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a worklist allocation in status created.
    static func newWorklistAllocation(_ code: String, name: String) -> WorklistAllocation {
        return WorklistAllocation(
            code: code,
            name: name,
            patientRef: "",
            region: "",
            quantity: 0,
            encounterID: "",
            cost: 0.0,
            clinicianID: "",
            expiresAt: 0,
            limit: 0,
            visible: false,
            status: WorklistAllocationStatus.created
        )
    }
}
