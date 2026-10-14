import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study metric is in its life cycle.
    enum StudyMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One study metric, with what the planners need to act on it.
    final class StudyMetric {
        var code: String
        var label: String
        var pinned: Bool
        var durationMinutes: Int
        var clinicianID: String
        var acuity: Int
        var status: StudyMetricStatus

        init(code: String, label: String, pinned: Bool, durationMinutes: Int, clinicianID: String, acuity: Int, status: StudyMetricStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.durationMinutes = durationMinutes
            self.clinicianID = clinicianID
            self.acuity = acuity
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

        func canMoveTo(_ next: StudyMetricStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == StudyMetricStatus.rejected || next == StudyMetricStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StudyMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return ((Double(durationMinutes) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> StudyMetric {
            return StudyMetric(
                code: code,
                label: label,
                pinned: pinned,
                durationMinutes: durationMinutes,
                clinicianID: clinicianID,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a study metric in status proposed.
    static func newStudyMetric(_ code: String, label: String) -> StudyMetric {
        return StudyMetric(
            code: code,
            label: label,
            pinned: false,
            durationMinutes: 0,
            clinicianID: "",
            acuity: 0,
            status: StudyMetricStatus.proposed
        )
    }
}
