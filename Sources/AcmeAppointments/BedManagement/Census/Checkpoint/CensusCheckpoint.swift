import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census checkpoint is in its life cycle.
    enum CensusCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A census checkpoint. Its code is unique within a tenant.
    final class CensusCheckpoint {
        var code: String
        var label: String
        var floorValue: Double
        var visitMinutes: Int
        var category: String
        var budget: Double
        var ceiling: Double
        var retries: Int
        var status: CensusCheckpointStatus

        init(code: String, label: String, floorValue: Double, visitMinutes: Int, category: String, budget: Double, ceiling: Double, retries: Int, status: CensusCheckpointStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.visitMinutes = visitMinutes
            self.category = category
            self.budget = budget
            self.ceiling = ceiling
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                return next == CensusCheckpointStatus.ready || next == CensusCheckpointStatus.draining
            case .warming:
                return next == CensusCheckpointStatus.draining
            case .ready:
                return next == CensusCheckpointStatus.draining
            case .draining:
                return next == CensusCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedTotal() -> Double {
            return ((ceiling - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> CensusCheckpoint {
            return CensusCheckpoint(
                code: code,
                label: label,
                floorValue: floorValue,
                visitMinutes: visitMinutes,
                category: category,
                budget: budget,
                ceiling: ceiling,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a census checkpoint in status idle.
    static func newCensusCheckpoint(_ code: String, label: String) -> CensusCheckpoint {
        return CensusCheckpoint(
            code: code,
            label: label,
            floorValue: 0.0,
            visitMinutes: 0,
            category: "",
            budget: 0.0,
            ceiling: 0.0,
            retries: 0,
            status: CensusCheckpointStatus.idle
        )
    }
}
