import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap override is in its life cycle.
    enum CareGapOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One care gap override, with what the planners need to act on it.
    final class CareGapOverride {
        var code: String
        var title: String
        var revision: Int
        var procedureCode: String
        var active: Bool
        var status: CareGapOverrideStatus

        init(code: String, title: String, revision: Int, procedureCode: String, active: Bool, status: CareGapOverrideStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.procedureCode = procedureCode
            self.active = active
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

        func canMoveTo(_ next: CareGapOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CareGapOverrideStatus.rejected || next == CareGapOverrideStatus.withdrawn
            case .rejected:
                return next == CareGapOverrideStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("care gap override") \(code)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> CareGapOverride {
            return CareGapOverride(
                code: code,
                title: title,
                revision: revision,
                procedureCode: procedureCode,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care gap override in status proposed.
    static func newCareGapOverride(_ code: String, title: String) -> CareGapOverride {
        return CareGapOverride(
            code: code,
            title: title,
            revision: 0,
            procedureCode: "",
            active: false,
            status: CareGapOverrideStatus.proposed
        )
    }
}
