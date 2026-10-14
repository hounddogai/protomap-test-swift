import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim score is in its life cycle.
    enum ClaimScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A claim score. Its code is unique within a tenant.
    final class ClaimScore {
        var code: String
        var title: String
        var encounterID: String
        var name: String
        var procedureCode: String
        var score: Double
        var status: ClaimScoreStatus

        init(code: String, title: String, encounterID: String, name: String, procedureCode: String, score: Double, status: ClaimScoreStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.name = name
            self.procedureCode = procedureCode
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimScoreStatus) -> Bool {
            switch status {
            case .draft:
                return next == ClaimScoreStatus.suspended
            case .pending:
                return next == ClaimScoreStatus.active || next == ClaimScoreStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ClaimScoreStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ClaimScore {
            return ClaimScore(
                code: code,
                title: title,
                encounterID: encounterID,
                name: name,
                procedureCode: procedureCode,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a claim score in status draft.
    static func newClaimScore(_ code: String, title: String) -> ClaimScore {
        return ClaimScore(
            code: code,
            title: title,
            encounterID: "",
            name: "",
            procedureCode: "",
            score: 0.0,
            status: ClaimScoreStatus.draft
        )
    }
}
