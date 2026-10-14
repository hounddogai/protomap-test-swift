import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback census snapshot is in its life cycle.
    enum FallbackCensusSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback census snapshot. Its code is unique within a tenant.
    final class FallbackCensusSnapshot {
        var code: String
        var name: String
        var attempts: Int
        var patientRef: String
        var procedureCode: String
        var reviewer: String
        var status: FallbackCensusSnapshotStatus

        init(code: String, name: String, attempts: Int, patientRef: String, procedureCode: String, reviewer: String, status: FallbackCensusSnapshotStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.patientRef = patientRef
            self.procedureCode = procedureCode
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackCensusSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == FallbackCensusSnapshotStatus.expired
            case .revoked:
                return next == FallbackCensusSnapshotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCensusSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback census snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> FallbackCensusSnapshot {
            return FallbackCensusSnapshot(
                code: code,
                name: name,
                attempts: attempts,
                patientRef: patientRef,
                procedureCode: procedureCode,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback census snapshot in status requested.
    static func newFallbackCensusSnapshot(_ code: String, name: String) -> FallbackCensusSnapshot {
        return FallbackCensusSnapshot(
            code: code,
            name: name,
            attempts: 0,
            patientRef: "",
            procedureCode: "",
            reviewer: "",
            status: FallbackCensusSnapshotStatus.requested
        )
    }
}
