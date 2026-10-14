import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol estimate is in its life cycle.
    enum CareProtocolEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care protocol estimate as the care protocol team keeps it.
    final class CareProtocolEstimate {
        var code: String
        var label: String
        var diagnosisCode: String
        var archived: Bool
        var visitMinutes: Int
        var graceDays: Int
        var notes: String
        var priority: Int
        var status: CareProtocolEstimateStatus

        init(code: String, label: String, diagnosisCode: String, archived: Bool, visitMinutes: Int, graceDays: Int, notes: String, priority: Int, status: CareProtocolEstimateStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
            self.notes = notes
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolEstimateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CareProtocolEstimateStatus.draining || next == CareProtocolEstimateStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CareProtocolEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netExposure() -> Double {
            return (Double(graceDays) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolEstimate {
            return CareProtocolEstimate(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                archived: archived,
                visitMinutes: visitMinutes,
                graceDays: graceDays,
                notes: notes,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol estimate in status idle.
    static func newCareProtocolEstimate(_ code: String, label: String) -> CareProtocolEstimate {
        return CareProtocolEstimate(
            code: code,
            label: label,
            diagnosisCode: "",
            archived: false,
            visitMinutes: 0,
            graceDays: 0,
            notes: "",
            priority: 0,
            status: CareProtocolEstimateStatus.idle
        )
    }
}
