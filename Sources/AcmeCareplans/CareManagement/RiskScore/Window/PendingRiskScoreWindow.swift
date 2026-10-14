import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending risk score window is in its life cycle.
    enum PendingRiskScoreWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending risk score window. Its code is unique within a tenant.
    final class PendingRiskScoreWindow {
        var code: String
        var label: String
        var graceDays: Int
        var refills: Int
        var contactEmail: String
        var patientRef: String
        var visitMinutes: Int
        var status: PendingRiskScoreWindowStatus

        init(code: String, label: String, graceDays: Int, refills: Int, contactEmail: String, patientRef: String, visitMinutes: Int, status: PendingRiskScoreWindowStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.refills = refills
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: PendingRiskScoreWindowStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PendingRiskScoreWindowStatus.running || next == PendingRiskScoreWindowStatus.failed
            case .running:
                return next == PendingRiskScoreWindowStatus.failed
            case .done:
                return next == PendingRiskScoreWindowStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingRiskScoreWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending risk score window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return ((Double(refills) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PendingRiskScoreWindow {
            return PendingRiskScoreWindow(
                code: code,
                label: label,
                graceDays: graceDays,
                refills: refills,
                contactEmail: contactEmail,
                patientRef: patientRef,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending risk score window in status new.
    static func newPendingRiskScoreWindow(_ code: String, label: String) -> PendingRiskScoreWindow {
        return PendingRiskScoreWindow(
            code: code,
            label: label,
            graceDays: 0,
            refills: 0,
            contactEmail: "",
            patientRef: "",
            visitMinutes: 0,
            status: PendingRiskScoreWindowStatus.new
        )
    }
}
