import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal isolation proposal is in its life cycle.
    enum SeasonalIsolationProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One seasonal isolation proposal, with what the planners need to act on it.
    final class SeasonalIsolationProposal {
        var code: String
        var title: String
        var revision: Int
        var archived: Bool
        var acuity: Int
        var maximum: Double
        var durationMinutes: Int
        var status: SeasonalIsolationProposalStatus

        init(code: String, title: String, revision: Int, archived: Bool, acuity: Int, maximum: Double, durationMinutes: Int, status: SeasonalIsolationProposalStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.archived = archived
            self.acuity = acuity
            self.maximum = maximum
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalIsolationProposalStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalIsolationProposalStatus.running
            case .queued:
                return next == SeasonalIsolationProposalStatus.done || next == SeasonalIsolationProposalStatus.failed
            case .running:
                return next == SeasonalIsolationProposalStatus.done || next == SeasonalIsolationProposalStatus.failed
            case .done:
                return next == SeasonalIsolationProposalStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalIsolationProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal isolation proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("seasonal isolation proposal") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((maximum - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalIsolationProposal {
            return SeasonalIsolationProposal(
                code: code,
                title: title,
                revision: revision,
                archived: archived,
                acuity: acuity,
                maximum: maximum,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal isolation proposal in status new.
    static func newSeasonalIsolationProposal(_ code: String, title: String) -> SeasonalIsolationProposal {
        return SeasonalIsolationProposal(
            code: code,
            title: title,
            revision: 0,
            archived: false,
            acuity: 0,
            maximum: 0.0,
            durationMinutes: 0,
            status: SeasonalIsolationProposalStatus.new
        )
    }
}
