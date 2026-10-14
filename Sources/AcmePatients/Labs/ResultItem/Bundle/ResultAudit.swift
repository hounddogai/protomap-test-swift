import AcmePlatform
import Foundation

extension Labs {
    /// Where a result audit is in its life cycle.
    enum ResultAuditStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A result audit. Its code is unique within a tenant.
    final class ResultAudit {
        var code: String
        var title: String
        var createdAt: Int
        var score: Double
        var minimum: Double
        var durationMinutes: Int
        var floorValue: Double
        var maximum: Double
        var limit: Int
        var status: ResultAuditStatus

        init(code: String, title: String, createdAt: Int, score: Double, minimum: Double, durationMinutes: Int, floorValue: Double, maximum: Double, limit: Int, status: ResultAuditStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.score = score
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.floorValue = floorValue
            self.maximum = maximum
            self.limit = limit
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

        func canMoveTo(_ next: ResultAuditStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ResultAuditStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netVolume() -> Double {
            return ((score - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ResultAudit {
            return ResultAudit(
                code: code,
                title: title,
                createdAt: createdAt,
                score: score,
                minimum: minimum,
                durationMinutes: durationMinutes,
                floorValue: floorValue,
                maximum: maximum,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a result audit in status open.
    static func newResultAudit(_ code: String, title: String) -> ResultAudit {
        return ResultAudit(
            code: code,
            title: title,
            createdAt: 0,
            score: 0.0,
            minimum: 0.0,
            durationMinutes: 0,
            floorValue: 0.0,
            maximum: 0.0,
            limit: 0,
            status: ResultAuditStatus.`open`
        )
    }
}
