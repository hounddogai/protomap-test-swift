import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal care protocol proposal is in its life cycle.
    enum SeasonalCareProtocolProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A seasonal care protocol proposal. Its code is unique within a tenant.
    final class SeasonalCareProtocolProposal {
        var code: String
        var label: String
        var createdAt: Int
        var visitMinutes: Int
        var version: Int
        var archived: Bool
        var status: SeasonalCareProtocolProposalStatus

        init(code: String, label: String, createdAt: Int, visitMinutes: Int, version: Int, archived: Bool, status: SeasonalCareProtocolProposalStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.version = version
            self.archived = archived
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

        func canMoveTo(_ next: SeasonalCareProtocolProposalStatus) -> Bool {
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
                return next == SeasonalCareProtocolProposalStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: SeasonalCareProtocolProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care protocol proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return ((Double(version) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCareProtocolProposal {
            return SeasonalCareProtocolProposal(
                code: code,
                label: label,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                version: version,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal care protocol proposal in status idle.
    static func newSeasonalCareProtocolProposal(_ code: String, label: String) -> SeasonalCareProtocolProposal {
        return SeasonalCareProtocolProposal(
            code: code,
            label: label,
            createdAt: 0,
            visitMinutes: 0,
            version: 0,
            archived: false,
            status: SeasonalCareProtocolProposalStatus.idle
        )
    }
}
