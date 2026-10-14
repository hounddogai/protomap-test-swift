import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending read draft is in its life cycle.
    enum PendingReadDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One pending read draft, with what the planners need to act on it.
    final class PendingReadDraft {
        var code: String
        var name: String
        var contactEmail: String
        var durationMinutes: Int
        var facility: String
        var endsAt: Int
        var createdAt: Int
        var category: String
        var reviewer: String
        var version: Int
        var status: PendingReadDraftStatus

        init(code: String, name: String, contactEmail: String, durationMinutes: Int, facility: String, endsAt: Int, createdAt: Int, category: String, reviewer: String, version: Int, status: PendingReadDraftStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.durationMinutes = durationMinutes
            self.facility = facility
            self.endsAt = endsAt
            self.createdAt = createdAt
            self.category = category
            self.reviewer = reviewer
            self.version = version
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

        func canMoveTo(_ next: PendingReadDraftStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingReadDraftStatus.resolved || next == PendingReadDraftStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PendingReadDraftStatus.reopened || next == PendingReadDraftStatus.archived
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

        func moveTo(_ next: PendingReadDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending read draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("pending read draft") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(createdAt) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> PendingReadDraft {
            return PendingReadDraft(
                code: code,
                name: name,
                contactEmail: contactEmail,
                durationMinutes: durationMinutes,
                facility: facility,
                endsAt: endsAt,
                createdAt: createdAt,
                category: category,
                reviewer: reviewer,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending read draft in status open.
    static func newPendingReadDraft(_ code: String, name: String) -> PendingReadDraft {
        return PendingReadDraft(
            code: code,
            name: name,
            contactEmail: "",
            durationMinutes: 0,
            facility: "",
            endsAt: 0,
            createdAt: 0,
            category: "",
            reviewer: "",
            version: 0,
            status: PendingReadDraftStatus.`open`
        )
    }
}
