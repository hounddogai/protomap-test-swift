import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy goal proposal is in its life cycle.
    enum LegacyGoalProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A legacy goal proposal as the goal team keeps it.
    final class LegacyGoalProposal {
        var code: String
        var title: String
        var weight: Double
        var source: String
        var retries: Int
        var threshold: Double
        var notes: String
        var checksum: String
        var updatedAt: Int
        var status: LegacyGoalProposalStatus

        init(code: String, title: String, weight: Double, source: String, retries: Int, threshold: Double, notes: String, checksum: String, updatedAt: Int, status: LegacyGoalProposalStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.source = source
            self.retries = retries
            self.threshold = threshold
            self.notes = notes
            self.checksum = checksum
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: LegacyGoalProposalStatus) -> Bool {
            switch status {
            case .idle:
                return next == LegacyGoalProposalStatus.ready || next == LegacyGoalProposalStatus.stopped
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LegacyGoalProposalStatus.draining || next == LegacyGoalProposalStatus.stopped
            case .draining:
                return next == LegacyGoalProposalStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyGoalProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy goal proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy goal proposal") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((threshold - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyGoalProposal {
            return LegacyGoalProposal(
                code: code,
                title: title,
                weight: weight,
                source: source,
                retries: retries,
                threshold: threshold,
                notes: notes,
                checksum: checksum,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a legacy goal proposal in status idle.
    static func newLegacyGoalProposal(_ code: String, title: String) -> LegacyGoalProposal {
        return LegacyGoalProposal(
            code: code,
            title: title,
            weight: 0.0,
            source: "",
            retries: 0,
            threshold: 0.0,
            notes: "",
            checksum: "",
            updatedAt: 0,
            status: LegacyGoalProposalStatus.idle
        )
    }
}
