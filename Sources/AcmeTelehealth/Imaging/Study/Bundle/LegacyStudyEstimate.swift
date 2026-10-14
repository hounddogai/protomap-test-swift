import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy study estimate is in its life cycle.
    enum LegacyStudyEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy study estimate. Its code is unique within a tenant.
    final class LegacyStudyEstimate {
        var code: String
        var title: String
        var diagnosisCode: String
        var visitMinutes: Int
        var score: Double
        var status: LegacyStudyEstimateStatus

        init(code: String, title: String, diagnosisCode: String, visitMinutes: Int, score: Double, status: LegacyStudyEstimateStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.visitMinutes = visitMinutes
            self.score = score
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

        func canMoveTo(_ next: LegacyStudyEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyStudyEstimateStatus.inReview || next == LegacyStudyEstimateStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyStudyEstimateStatus.reopened || next == LegacyStudyEstimateStatus.archived
            case .reopened:
                return next == LegacyStudyEstimateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyStudyEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy study estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy study estimate") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(visitMinutes) - score) * 100).rounded() / 100
        }

        func copyValue() -> LegacyStudyEstimate {
            return LegacyStudyEstimate(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                visitMinutes: visitMinutes,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy study estimate in status open.
    static func newLegacyStudyEstimate(_ code: String, title: String) -> LegacyStudyEstimate {
        return LegacyStudyEstimate(
            code: code,
            title: title,
            diagnosisCode: "",
            visitMinutes: 0,
            score: 0.0,
            status: LegacyStudyEstimateStatus.`open`
        )
    }
}
