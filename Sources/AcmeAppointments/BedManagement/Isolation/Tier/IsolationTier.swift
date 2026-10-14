import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation tier is in its life cycle.
    enum IsolationTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One isolation tier, with what the planners need to act on it.
    final class IsolationTier {
        var code: String
        var name: String
        var expiresAt: Int
        var amount: Double
        var encounterID: String
        var revision: Int
        var status: IsolationTierStatus

        init(code: String, name: String, expiresAt: Int, amount: Double, encounterID: String, revision: Int, status: IsolationTierStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.amount = amount
            self.encounterID = encounterID
            self.revision = revision
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

        func canMoveTo(_ next: IsolationTierStatus) -> Bool {
            switch status {
            case .draft:
                return next == IsolationTierStatus.active || next == IsolationTierStatus.suspended
            case .pending:
                switch next {
                case .active:
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

        func moveTo(_ next: IsolationTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("isolation tier") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((amount + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> IsolationTier {
            return IsolationTier(
                code: code,
                name: name,
                expiresAt: expiresAt,
                amount: amount,
                encounterID: encounterID,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a isolation tier in status draft.
    static func newIsolationTier(_ code: String, name: String) -> IsolationTier {
        return IsolationTier(
            code: code,
            name: name,
            expiresAt: 0,
            amount: 0.0,
            encounterID: "",
            revision: 0,
            status: IsolationTierStatus.draft
        )
    }
}
