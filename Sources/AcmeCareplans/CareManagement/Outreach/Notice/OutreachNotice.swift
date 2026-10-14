import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach notice is in its life cycle.
    enum OutreachNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One outreach notice, with what the planners need to act on it.
    final class OutreachNotice {
        var code: String
        var label: String
        var retries: Int
        var diagnosisCode: String
        var updatedAt: Int
        var rate: Double
        var source: String
        var procedureCode: String
        var score: Double
        var approved: Bool
        var status: OutreachNoticeStatus

        init(code: String, label: String, retries: Int, diagnosisCode: String, updatedAt: Int, rate: Double, source: String, procedureCode: String, score: Double, approved: Bool, status: OutreachNoticeStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.diagnosisCode = diagnosisCode
            self.updatedAt = updatedAt
            self.rate = rate
            self.source = source
            self.procedureCode = procedureCode
            self.score = score
            self.approved = approved
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

        func canMoveTo(_ next: OutreachNoticeStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: OutreachNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return ((Double(updatedAt) - rate) * 100).rounded() / 100
        }

        func copyValue() -> OutreachNotice {
            return OutreachNotice(
                code: code,
                label: label,
                retries: retries,
                diagnosisCode: diagnosisCode,
                updatedAt: updatedAt,
                rate: rate,
                source: source,
                procedureCode: procedureCode,
                score: score,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a outreach notice in status planned.
    static func newOutreachNotice(_ code: String, label: String) -> OutreachNotice {
        return OutreachNotice(
            code: code,
            label: label,
            retries: 0,
            diagnosisCode: "",
            updatedAt: 0,
            rate: 0.0,
            source: "",
            procedureCode: "",
            score: 0.0,
            approved: false,
            status: OutreachNoticeStatus.planned
        )
    }
}
