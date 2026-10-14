import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment request is in its life cycle.
    enum AssessmentRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a assessment request and its current status.
    final class AssessmentRequest {
        var code: String
        var title: String
        var updatedAt: Int
        var attempts: Int
        var procedureCode: String
        var summary: String
        var score: Double
        var version: Int
        var status: AssessmentRequestStatus

        init(code: String, title: String, updatedAt: Int, attempts: Int, procedureCode: String, summary: String, score: Double, version: Int, status: AssessmentRequestStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.attempts = attempts
            self.procedureCode = procedureCode
            self.summary = summary
            self.score = score
            self.version = version
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

        func canMoveTo(_ next: AssessmentRequestStatus) -> Bool {
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
                return next == AssessmentRequestStatus.ready || next == AssessmentRequestStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AssessmentRequestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedTotal() -> Double {
            return (Double(version) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentRequest {
            return AssessmentRequest(
                code: code,
                title: title,
                updatedAt: updatedAt,
                attempts: attempts,
                procedureCode: procedureCode,
                summary: summary,
                score: score,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a assessment request in status idle.
    static func newAssessmentRequest(_ code: String, title: String) -> AssessmentRequest {
        return AssessmentRequest(
            code: code,
            title: title,
            updatedAt: 0,
            attempts: 0,
            procedureCode: "",
            summary: "",
            score: 0.0,
            version: 0,
            status: AssessmentRequestStatus.idle
        )
    }
}
