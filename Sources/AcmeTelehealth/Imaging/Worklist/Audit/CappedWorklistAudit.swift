import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped worklist audit is in its life cycle.
    enum CappedWorklistAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One capped worklist audit, with what the planners need to act on it.
    final class CappedWorklistAudit {
        var code: String
        var label: String
        var clinicianID: String
        var visitMinutes: Int
        var checksum: String
        var margin: Double
        var visible: Bool
        var graceDays: Int
        var status: CappedWorklistAuditStatus

        init(code: String, label: String, clinicianID: String, visitMinutes: Int, checksum: String, margin: Double, visible: Bool, graceDays: Int, status: CappedWorklistAuditStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.margin = margin
            self.visible = visible
            self.graceDays = graceDays
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

        func canMoveTo(_ next: CappedWorklistAuditStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedWorklistAuditStatus.queued || next == CappedWorklistAuditStatus.failed
            case .queued:
                return next == CappedWorklistAuditStatus.done
            case .running:
                return next == CappedWorklistAuditStatus.done || next == CappedWorklistAuditStatus.failed
            case .done:
                return next == CappedWorklistAuditStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedWorklistAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped worklist audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveVolume() -> Double {
            return ((margin + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> CappedWorklistAudit {
            return CappedWorklistAudit(
                code: code,
                label: label,
                clinicianID: clinicianID,
                visitMinutes: visitMinutes,
                checksum: checksum,
                margin: margin,
                visible: visible,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped worklist audit in status new.
    static func newCappedWorklistAudit(_ code: String, label: String) -> CappedWorklistAudit {
        return CappedWorklistAudit(
            code: code,
            label: label,
            clinicianID: "",
            visitMinutes: 0,
            checksum: "",
            margin: 0.0,
            visible: false,
            graceDays: 0,
            status: CappedWorklistAuditStatus.new
        )
    }
}
