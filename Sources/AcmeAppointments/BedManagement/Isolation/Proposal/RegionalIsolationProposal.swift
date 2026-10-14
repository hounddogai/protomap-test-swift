import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional isolation proposal is in its life cycle.
    enum RegionalIsolationProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a regional isolation proposal and its current status.
    final class RegionalIsolationProposal {
        var code: String
        var title: String
        var margin: Double
        var limit: Int
        var version: Int
        var minimum: Double
        var status: RegionalIsolationProposalStatus

        init(code: String, title: String, margin: Double, limit: Int, version: Int, minimum: Double, status: RegionalIsolationProposalStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.limit = limit
            self.version = version
            self.minimum = minimum
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

        func canMoveTo(_ next: RegionalIsolationProposalStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RegionalIsolationProposalStatus.suspended
            case .suspended:
                return next == RegionalIsolationProposalStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalIsolationProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional isolation proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("regional isolation proposal") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((minimum + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalIsolationProposal {
            return RegionalIsolationProposal(
                code: code,
                title: title,
                margin: margin,
                limit: limit,
                version: version,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional isolation proposal in status draft.
    static func newRegionalIsolationProposal(_ code: String, title: String) -> RegionalIsolationProposal {
        return RegionalIsolationProposal(
            code: code,
            title: title,
            margin: 0.0,
            limit: 0,
            version: 0,
            minimum: 0.0,
            status: RegionalIsolationProposalStatus.draft
        )
    }
}
