import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up mapping is in its life cycle.
    enum FollowUpMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A follow up mapping as the follow up team keeps it.
    final class FollowUpMapping {
        var code: String
        var title: String
        var score: Double
        var diagnosisCode: String
        var visitMinutes: Int
        var status: FollowUpMappingStatus

        init(code: String, title: String, score: Double, diagnosisCode: String, visitMinutes: Int, status: FollowUpMappingStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.diagnosisCode = diagnosisCode
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: FollowUpMappingStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: FollowUpMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedLoad() -> Double {
            return ((Double(visitMinutes) - score) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpMapping {
            return FollowUpMapping(
                code: code,
                title: title,
                score: score,
                diagnosisCode: diagnosisCode,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a follow up mapping in status draft.
    static func newFollowUpMapping(_ code: String, title: String) -> FollowUpMapping {
        return FollowUpMapping(
            code: code,
            title: title,
            score: 0.0,
            diagnosisCode: "",
            visitMinutes: 0,
            status: FollowUpMappingStatus.draft
        )
    }
}
