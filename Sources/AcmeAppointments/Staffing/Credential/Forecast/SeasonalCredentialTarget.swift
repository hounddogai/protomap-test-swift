import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal credential target is in its life cycle.
    enum SeasonalCredentialTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A seasonal credential target. Its code is unique within a tenant.
    final class SeasonalCredentialTarget {
        var code: String
        var name: String
        var diagnosisCode: String
        var durationMinutes: Int
        var sequence: Int
        var status: SeasonalCredentialTargetStatus

        init(code: String, name: String, diagnosisCode: String, durationMinutes: Int, sequence: Int, status: SeasonalCredentialTargetStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.durationMinutes = durationMinutes
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalCredentialTargetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SeasonalCredentialTargetStatus.active || next == SeasonalCredentialTargetStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SeasonalCredentialTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCredentialTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal credential target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return ((Double(sequence) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCredentialTarget {
            return SeasonalCredentialTarget(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                durationMinutes: durationMinutes,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal credential target in status draft.
    static func newSeasonalCredentialTarget(_ code: String, name: String) -> SeasonalCredentialTarget {
        return SeasonalCredentialTarget(
            code: code,
            name: name,
            diagnosisCode: "",
            durationMinutes: 0,
            sequence: 0,
            status: SeasonalCredentialTargetStatus.draft
        )
    }
}
