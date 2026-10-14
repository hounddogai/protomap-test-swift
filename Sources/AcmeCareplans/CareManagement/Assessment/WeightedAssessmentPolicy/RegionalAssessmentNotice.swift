import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional assessment notice is in its life cycle.
    enum RegionalAssessmentNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One regional assessment notice, with what the planners need to act on it.
    final class RegionalAssessmentNotice {
        var code: String
        var label: String
        var revision: Int
        var dosageMg: Double
        var retries: Int
        var facility: String
        var expiresAt: Int
        var status: RegionalAssessmentNoticeStatus

        init(code: String, label: String, revision: Int, dosageMg: Double, retries: Int, facility: String, expiresAt: Int, status: RegionalAssessmentNoticeStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.dosageMg = dosageMg
            self.retries = retries
            self.facility = facility
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: RegionalAssessmentNoticeStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RegionalAssessmentNoticeStatus.inProgress || next == RegionalAssessmentNoticeStatus.completed
            case .inProgress:
                return next == RegionalAssessmentNoticeStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAssessmentNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional assessment notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveVolume() -> Double {
            return (Double(retries) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> RegionalAssessmentNotice {
            return RegionalAssessmentNotice(
                code: code,
                label: label,
                revision: revision,
                dosageMg: dosageMg,
                retries: retries,
                facility: facility,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional assessment notice in status planned.
    static func newRegionalAssessmentNotice(_ code: String, label: String) -> RegionalAssessmentNotice {
        return RegionalAssessmentNotice(
            code: code,
            label: label,
            revision: 0,
            dosageMg: 0.0,
            retries: 0,
            facility: "",
            expiresAt: 0,
            status: RegionalAssessmentNoticeStatus.planned
        )
    }
}
