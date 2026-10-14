import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score notice is in its life cycle.
    enum RiskScoreNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a risk score notice and its current status.
    final class RiskScoreNotice {
        var code: String
        var name: String
        var revision: Int
        var windowDays: Int
        var procedureCode: String
        var source: String
        var threshold: Double
        var diagnosisCode: String
        var priority: Int
        var status: RiskScoreNoticeStatus

        init(code: String, name: String, revision: Int, windowDays: Int, procedureCode: String, source: String, threshold: Double, diagnosisCode: String, priority: Int, status: RiskScoreNoticeStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.windowDays = windowDays
            self.procedureCode = procedureCode
            self.source = source
            self.threshold = threshold
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RiskScoreNoticeStatus.reopened || next == RiskScoreNoticeStatus.archived
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RiskScoreNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("risk score notice") \(code)"
        }

        func projectedLoad() -> Double {
            return (Double(revision) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreNotice {
            return RiskScoreNotice(
                code: code,
                name: name,
                revision: revision,
                windowDays: windowDays,
                procedureCode: procedureCode,
                source: source,
                threshold: threshold,
                diagnosisCode: diagnosisCode,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a risk score notice in status open.
    static func newRiskScoreNotice(_ code: String, name: String) -> RiskScoreNotice {
        return RiskScoreNotice(
            code: code,
            name: name,
            revision: 0,
            windowDays: 0,
            procedureCode: "",
            source: "",
            threshold: 0.0,
            diagnosisCode: "",
            priority: 0,
            status: RiskScoreNoticeStatus.`open`
        )
    }
}
