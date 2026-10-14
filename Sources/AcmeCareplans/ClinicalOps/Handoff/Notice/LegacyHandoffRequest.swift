import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy handoff request is in its life cycle.
    enum LegacyHandoffRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a legacy handoff request and its current status.
    final class LegacyHandoffRequest {
        var code: String
        var label: String
        var graceDays: Int
        var minimum: Double
        var startsAt: Int
        var archived: Bool
        var status: LegacyHandoffRequestStatus

        init(code: String, label: String, graceDays: Int, minimum: Double, startsAt: Int, archived: Bool, status: LegacyHandoffRequestStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.minimum = minimum
            self.startsAt = startsAt
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

        func canMoveTo(_ next: LegacyHandoffRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LegacyHandoffRequestStatus.suspended || next == LegacyHandoffRequestStatus.closed
            case .suspended:
                return next == LegacyHandoffRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyHandoffRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy handoff request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveTotal() -> Double {
            return ((Double(graceDays) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> LegacyHandoffRequest {
            return LegacyHandoffRequest(
                code: code,
                label: label,
                graceDays: graceDays,
                minimum: minimum,
                startsAt: startsAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy handoff request in status draft.
    static func newLegacyHandoffRequest(_ code: String, label: String) -> LegacyHandoffRequest {
        return LegacyHandoffRequest(
            code: code,
            label: label,
            graceDays: 0,
            minimum: 0.0,
            startsAt: 0,
            archived: false,
            status: LegacyHandoffRequestStatus.draft
        )
    }
}
