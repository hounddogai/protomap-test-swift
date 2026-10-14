import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling reference range rollup is in its life cycle.
    enum RollingReferenceRangeRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling reference range rollup. Its code is unique within a tenant.
    final class RollingReferenceRangeRollup {
        var code: String
        var label: String
        var procedureCode: String
        var graceDays: Int
        var timezone: String
        var facility: String
        var budget: Double
        var checksum: String
        var retries: Int
        var attempts: Int
        var revision: Int
        var status: RollingReferenceRangeRollupStatus

        init(code: String, label: String, procedureCode: String, graceDays: Int, timezone: String, facility: String, budget: Double, checksum: String, retries: Int, attempts: Int, revision: Int, status: RollingReferenceRangeRollupStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.graceDays = graceDays
            self.timezone = timezone
            self.facility = facility
            self.budget = budget
            self.checksum = checksum
            self.retries = retries
            self.attempts = attempts
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingReferenceRangeRollupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RollingReferenceRangeRollupStatus.done || next == RollingReferenceRangeRollupStatus.failed
            case .running:
                return next == RollingReferenceRangeRollupStatus.done || next == RollingReferenceRangeRollupStatus.failed
            case .done:
                return next == RollingReferenceRangeRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingReferenceRangeRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling reference range rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedLoad() -> Double {
            return ((Double(revision) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> RollingReferenceRangeRollup {
            return RollingReferenceRangeRollup(
                code: code,
                label: label,
                procedureCode: procedureCode,
                graceDays: graceDays,
                timezone: timezone,
                facility: facility,
                budget: budget,
                checksum: checksum,
                retries: retries,
                attempts: attempts,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rolling reference range rollup in status new.
    static func newRollingReferenceRangeRollup(_ code: String, label: String) -> RollingReferenceRangeRollup {
        return RollingReferenceRangeRollup(
            code: code,
            label: label,
            procedureCode: "",
            graceDays: 0,
            timezone: "",
            facility: "",
            budget: 0.0,
            checksum: "",
            retries: 0,
            attempts: 0,
            revision: 0,
            status: RollingReferenceRangeRollupStatus.new
        )
    }
}
