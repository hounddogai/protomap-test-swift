import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal overtime digest is in its life cycle.
    enum SeasonalOvertimeDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal overtime digest as the overtime team keeps it.
    final class SeasonalOvertimeDigest {
        var code: String
        var name: String
        var ceiling: Double
        var patientRef: String
        var ownerID: String
        var description: String
        var status: SeasonalOvertimeDigestStatus

        init(code: String, name: String, ceiling: Double, patientRef: String, ownerID: String, description: String, status: SeasonalOvertimeDigestStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.patientRef = patientRef
            self.ownerID = ownerID
            self.description = description
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

        func canMoveTo(_ next: SeasonalOvertimeDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalOvertimeDigestStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == SeasonalOvertimeDigestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalOvertimeDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal overtime digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> SeasonalOvertimeDigest {
            return SeasonalOvertimeDigest(
                code: code,
                name: name,
                ceiling: ceiling,
                patientRef: patientRef,
                ownerID: ownerID,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal overtime digest in status proposed.
    static func newSeasonalOvertimeDigest(_ code: String, name: String) -> SeasonalOvertimeDigest {
        return SeasonalOvertimeDigest(
            code: code,
            name: name,
            ceiling: 0.0,
            patientRef: "",
            ownerID: "",
            description: "",
            status: SeasonalOvertimeDigestStatus.proposed
        )
    }
}
