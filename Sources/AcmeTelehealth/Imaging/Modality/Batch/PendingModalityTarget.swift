import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending modality target is in its life cycle.
    enum PendingModalityTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending modality target as the modality team keeps it.
    final class PendingModalityTarget {
        var code: String
        var label: String
        var checksum: String
        var priority: Int
        var pinned: Bool
        var locale: String
        var encounterID: String
        var archived: Bool
        var acuity: Int
        var contactEmail: String
        var summary: String
        var status: PendingModalityTargetStatus

        init(code: String, label: String, checksum: String, priority: Int, pinned: Bool, locale: String, encounterID: String, archived: Bool, acuity: Int, contactEmail: String, summary: String, status: PendingModalityTargetStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.priority = priority
            self.pinned = pinned
            self.locale = locale
            self.encounterID = encounterID
            self.archived = archived
            self.acuity = acuity
            self.contactEmail = contactEmail
            self.summary = summary
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

        func canMoveTo(_ next: PendingModalityTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PendingModalityTargetStatus.resolved || next == PendingModalityTargetStatus.archived
            case .resolved:
                return next == PendingModalityTargetStatus.reopened
            case .reopened:
                return next == PendingModalityTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingModalityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending modality target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netVolume() -> Double {
            return ((Double(acuity) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PendingModalityTarget {
            return PendingModalityTarget(
                code: code,
                label: label,
                checksum: checksum,
                priority: priority,
                pinned: pinned,
                locale: locale,
                encounterID: encounterID,
                archived: archived,
                acuity: acuity,
                contactEmail: contactEmail,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending modality target in status open.
    static func newPendingModalityTarget(_ code: String, label: String) -> PendingModalityTarget {
        return PendingModalityTarget(
            code: code,
            label: label,
            checksum: "",
            priority: 0,
            pinned: false,
            locale: "",
            encounterID: "",
            archived: false,
            acuity: 0,
            contactEmail: "",
            summary: "",
            status: PendingModalityTargetStatus.`open`
        )
    }
}
