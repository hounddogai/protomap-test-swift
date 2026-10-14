import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped consent form notice is in its life cycle.
    enum CappedConsentFormNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A capped consent form notice as the consent form team keeps it.
    final class CappedConsentFormNotice {
        var code: String
        var title: String
        var tags: [String]
        var revision: Int
        var source: String
        var createdAt: Int
        var category: String
        var attempts: Int
        var status: CappedConsentFormNoticeStatus

        init(code: String, title: String, tags: [String], revision: Int, source: String, createdAt: Int, category: String, attempts: Int, status: CappedConsentFormNoticeStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.revision = revision
            self.source = source
            self.createdAt = createdAt
            self.category = category
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedConsentFormNoticeStatus) -> Bool {
            switch status {
            case .planned:
                return next == CappedConsentFormNoticeStatus.cancelled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CappedConsentFormNoticeStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedConsentFormNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped consent form notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("capped consent form notice") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return (Double(createdAt) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> CappedConsentFormNotice {
            return CappedConsentFormNotice(
                code: code,
                title: title,
                tags: tags,
                revision: revision,
                source: source,
                createdAt: createdAt,
                category: category,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped consent form notice in status planned.
    static func newCappedConsentFormNotice(_ code: String, title: String) -> CappedConsentFormNotice {
        return CappedConsentFormNotice(
            code: code,
            title: title,
            tags: [],
            revision: 0,
            source: "",
            createdAt: 0,
            category: "",
            attempts: 0,
            status: CappedConsentFormNoticeStatus.planned
        )
    }
}
