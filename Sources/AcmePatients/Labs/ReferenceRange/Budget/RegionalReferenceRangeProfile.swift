import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional reference range profile is in its life cycle.
    enum RegionalReferenceRangeProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A regional reference range profile as the reference range team keeps it.
    final class RegionalReferenceRangeProfile {
        var code: String
        var label: String
        var reviewer: String
        var revision: Int
        var durationMinutes: Int
        var procedureCode: String
        var status: RegionalReferenceRangeProfileStatus

        init(code: String, label: String, reviewer: String, revision: Int, durationMinutes: Int, procedureCode: String, status: RegionalReferenceRangeProfileStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.revision = revision
            self.durationMinutes = durationMinutes
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: RegionalReferenceRangeProfileStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalReferenceRangeProfileStatus.done
            case .queued:
                return next == RegionalReferenceRangeProfileStatus.done || next == RegionalReferenceRangeProfileStatus.failed
            case .running:
                return next == RegionalReferenceRangeProfileStatus.done || next == RegionalReferenceRangeProfileStatus.failed
            case .done:
                return next == RegionalReferenceRangeProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalReferenceRangeProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional reference range profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("regional reference range profile") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(revision) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RegionalReferenceRangeProfile {
            return RegionalReferenceRangeProfile(
                code: code,
                label: label,
                reviewer: reviewer,
                revision: revision,
                durationMinutes: durationMinutes,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional reference range profile in status new.
    static func newRegionalReferenceRangeProfile(_ code: String, label: String) -> RegionalReferenceRangeProfile {
        return RegionalReferenceRangeProfile(
            code: code,
            label: label,
            reviewer: "",
            revision: 0,
            durationMinutes: 0,
            procedureCode: "",
            status: RegionalReferenceRangeProfileStatus.new
        )
    }
}
