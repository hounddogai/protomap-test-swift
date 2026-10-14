import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped panel group is in its life cycle.
    enum CappedPanelGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A capped panel group. Its code is unique within a tenant.
    final class CappedPanelGroup {
        var code: String
        var name: String
        var retries: Int
        var rate: Double
        var archived: Bool
        var status: CappedPanelGroupStatus

        init(code: String, name: String, retries: Int, rate: Double, archived: Bool, status: CappedPanelGroupStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.rate = rate
            self.archived = archived
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

        func canMoveTo(_ next: CappedPanelGroupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CappedPanelGroupStatus.closed
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

        func moveTo(_ next: CappedPanelGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped panel group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped panel group") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(retries) + rate) * 100).rounded() / 100
        }

        func copyValue() -> CappedPanelGroup {
            return CappedPanelGroup(
                code: code,
                name: name,
                retries: retries,
                rate: rate,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped panel group in status draft.
    static func newCappedPanelGroup(_ code: String, name: String) -> CappedPanelGroup {
        return CappedPanelGroup(
            code: code,
            name: name,
            retries: 0,
            rate: 0.0,
            archived: false,
            status: CappedPanelGroupStatus.draft
        )
    }
}
