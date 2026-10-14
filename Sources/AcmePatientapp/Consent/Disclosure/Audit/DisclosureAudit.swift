import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure audit is in its life cycle.
    enum DisclosureAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a disclosure audit and its current status.
    final class DisclosureAudit {
        var code: String
        var label: String
        var graceDays: Int
        var segment: String
        var margin: Double
        var pinned: Bool
        var timezone: String
        var archived: Bool
        var payer: String
        var status: DisclosureAuditStatus

        init(code: String, label: String, graceDays: Int, segment: String, margin: Double, pinned: Bool, timezone: String, archived: Bool, payer: String, status: DisclosureAuditStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.segment = segment
            self.margin = margin
            self.pinned = pinned
            self.timezone = timezone
            self.archived = archived
            self.payer = payer
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

        func canMoveTo(_ next: DisclosureAuditStatus) -> Bool {
            switch status {
            case .draft:
                return next == DisclosureAuditStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: DisclosureAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("disclosure audit") \(code)"
        }

        func weightedVolume() -> Double {
            return ((margin - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureAudit {
            return DisclosureAudit(
                code: code,
                label: label,
                graceDays: graceDays,
                segment: segment,
                margin: margin,
                pinned: pinned,
                timezone: timezone,
                archived: archived,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a disclosure audit in status draft.
    static func newDisclosureAudit(_ code: String, label: String) -> DisclosureAudit {
        return DisclosureAudit(
            code: code,
            label: label,
            graceDays: 0,
            segment: "",
            margin: 0.0,
            pinned: false,
            timezone: "",
            archived: false,
            payer: "",
            status: DisclosureAuditStatus.draft
        )
    }
}
