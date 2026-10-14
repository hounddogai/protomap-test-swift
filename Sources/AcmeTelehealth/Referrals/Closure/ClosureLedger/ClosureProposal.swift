import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure proposal is in its life cycle.
    enum ClosureProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One closure proposal, with what the planners need to act on it.
    final class ClosureProposal {
        var code: String
        var title: String
        var durationMinutes: Int
        var reviewer: String
        var diagnosisCode: String
        var checksum: String
        var windowDays: Int
        var summary: String
        var margin: Double
        var status: ClosureProposalStatus

        init(code: String, title: String, durationMinutes: Int, reviewer: String, diagnosisCode: String, checksum: String, windowDays: Int, summary: String, margin: Double, status: ClosureProposalStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.reviewer = reviewer
            self.diagnosisCode = diagnosisCode
            self.checksum = checksum
            self.windowDays = windowDays
            self.summary = summary
            self.margin = margin
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

        func canMoveTo(_ next: ClosureProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ClosureProposalStatus.inReview || next == ClosureProposalStatus.reopened
            case .inReview:
                return next == ClosureProposalStatus.resolved || next == ClosureProposalStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ClosureProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return ((margin + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ClosureProposal {
            return ClosureProposal(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                reviewer: reviewer,
                diagnosisCode: diagnosisCode,
                checksum: checksum,
                windowDays: windowDays,
                summary: summary,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a closure proposal in status open.
    static func newClosureProposal(_ code: String, title: String) -> ClosureProposal {
        return ClosureProposal(
            code: code,
            title: title,
            durationMinutes: 0,
            reviewer: "",
            diagnosisCode: "",
            checksum: "",
            windowDays: 0,
            summary: "",
            margin: 0.0,
            status: ClosureProposalStatus.`open`
        )
    }
}
