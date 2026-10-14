import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default goal proposal is in its life cycle.
    enum DefaultGoalProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One default goal proposal, with what the planners need to act on it.
    final class DefaultGoalProposal {
        var code: String
        var name: String
        var ceiling: Double
        var approved: Bool
        var expiresAt: Int
        var country: String
        var revision: Int
        var status: DefaultGoalProposalStatus

        init(code: String, name: String, ceiling: Double, approved: Bool, expiresAt: Int, country: String, revision: Int, status: DefaultGoalProposalStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.approved = approved
            self.expiresAt = expiresAt
            self.country = country
            self.revision = revision
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

        func canMoveTo(_ next: DefaultGoalProposalStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultGoalProposalStatus.queued || next == DefaultGoalProposalStatus.running
            case .queued:
                return next == DefaultGoalProposalStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: DefaultGoalProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default goal proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("default goal proposal") \(code)"
        }

        func weightedVolume() -> Double {
            return ((ceiling + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultGoalProposal {
            return DefaultGoalProposal(
                code: code,
                name: name,
                ceiling: ceiling,
                approved: approved,
                expiresAt: expiresAt,
                country: country,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default goal proposal in status new.
    static func newDefaultGoalProposal(_ code: String, name: String) -> DefaultGoalProposal {
        return DefaultGoalProposal(
            code: code,
            name: name,
            ceiling: 0.0,
            approved: false,
            expiresAt: 0,
            country: "",
            revision: 0,
            status: DefaultGoalProposalStatus.new
        )
    }
}
