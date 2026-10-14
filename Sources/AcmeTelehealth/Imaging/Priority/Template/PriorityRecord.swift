import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority record is in its life cycle.
    enum PriorityRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a priority record and its current status.
    final class PriorityRecord {
        var code: String
        var name: String
        var cost: Double
        var reviewer: String
        var minimum: Double
        var copay: Double
        var version: Int
        var status: PriorityRecordStatus

        init(code: String, name: String, cost: Double, reviewer: String, minimum: Double, copay: Double, version: Int, status: PriorityRecordStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.reviewer = reviewer
            self.minimum = minimum
            self.copay = copay
            self.version = version
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

        func canMoveTo(_ next: PriorityRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PriorityRecordStatus.rejected || next == PriorityRecordStatus.withdrawn
            case .rejected:
                return next == PriorityRecordStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return ((copay - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityRecord {
            return PriorityRecord(
                code: code,
                name: name,
                cost: cost,
                reviewer: reviewer,
                minimum: minimum,
                copay: copay,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a priority record in status proposed.
    static func newPriorityRecord(_ code: String, name: String) -> PriorityRecord {
        return PriorityRecord(
            code: code,
            name: name,
            cost: 0.0,
            reviewer: "",
            minimum: 0.0,
            copay: 0.0,
            version: 0,
            status: PriorityRecordStatus.proposed
        )
    }
}
