import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census rollup is in its life cycle.
    enum CensusRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A census rollup. Its code is unique within a tenant.
    final class CensusRollup {
        var code: String
        var name: String
        var facility: String
        var rate: Double
        var procedureCode: String
        var status: CensusRollupStatus

        init(code: String, name: String, facility: String, rate: Double, procedureCode: String, status: CensusRollupStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.rate = rate
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusRollupStatus) -> Bool {
            switch status {
            case .planned:
                return next == CensusRollupStatus.inProgress
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CensusRollupStatus.cancelled
            case .completed:
                return next == CensusRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> CensusRollup {
            return CensusRollup(
                code: code,
                name: name,
                facility: facility,
                rate: rate,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a census rollup in status planned.
    static func newCensusRollup(_ code: String, name: String) -> CensusRollup {
        return CensusRollup(
            code: code,
            name: name,
            facility: "",
            rate: 0.0,
            procedureCode: "",
            status: CensusRollupStatus.planned
        )
    }
}
