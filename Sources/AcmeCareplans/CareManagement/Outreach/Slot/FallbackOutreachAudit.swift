import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback outreach audit is in its life cycle.
    enum FallbackOutreachAuditStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One fallback outreach audit, with what the planners need to act on it.
    final class FallbackOutreachAudit {
        var code: String
        var title: String
        var contactEmail: String
        var windowDays: Int
        var startsAt: Int
        var margin: Double
        var active: Bool
        var facility: String
        var sequence: Int
        var visible: Bool
        var status: FallbackOutreachAuditStatus

        init(code: String, title: String, contactEmail: String, windowDays: Int, startsAt: Int, margin: Double, active: Bool, facility: String, sequence: Int, visible: Bool, status: FallbackOutreachAuditStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.margin = margin
            self.active = active
            self.facility = facility
            self.sequence = sequence
            self.visible = visible
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

        func canMoveTo(_ next: FallbackOutreachAuditStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == FallbackOutreachAuditStatus.reopened || next == FallbackOutreachAuditStatus.archived
            case .resolved:
                return next == FallbackOutreachAuditStatus.reopened || next == FallbackOutreachAuditStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: FallbackOutreachAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback outreach audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback outreach audit") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(windowDays) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackOutreachAudit {
            return FallbackOutreachAudit(
                code: code,
                title: title,
                contactEmail: contactEmail,
                windowDays: windowDays,
                startsAt: startsAt,
                margin: margin,
                active: active,
                facility: facility,
                sequence: sequence,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback outreach audit in status open.
    static func newFallbackOutreachAudit(_ code: String, title: String) -> FallbackOutreachAudit {
        return FallbackOutreachAudit(
            code: code,
            title: title,
            contactEmail: "",
            windowDays: 0,
            startsAt: 0,
            margin: 0.0,
            active: false,
            facility: "",
            sequence: 0,
            visible: false,
            status: FallbackOutreachAuditStatus.`open`
        )
    }
}
