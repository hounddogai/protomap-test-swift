import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal slot notice is in its life cycle.
    enum SeasonalSlotNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a seasonal slot notice and its current status.
    final class SeasonalSlotNotice {
        var code: String
        var label: String
        var startsAt: Int
        var sequence: Int
        var attempts: Int
        var currency: String
        var tags: [String]
        var quantity: Int
        var encounterID: String
        var archived: Bool
        var version: Int
        var status: SeasonalSlotNoticeStatus

        init(code: String, label: String, startsAt: Int, sequence: Int, attempts: Int, currency: String, tags: [String], quantity: Int, encounterID: String, archived: Bool, version: Int, status: SeasonalSlotNoticeStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.sequence = sequence
            self.attempts = attempts
            self.currency = currency
            self.tags = tags
            self.quantity = quantity
            self.encounterID = encounterID
            self.archived = archived
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

        func canMoveTo(_ next: SeasonalSlotNoticeStatus) -> Bool {
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
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == SeasonalSlotNoticeStatus.reopened || next == SeasonalSlotNoticeStatus.archived
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

        func moveTo(_ next: SeasonalSlotNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal slot notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return ((Double(startsAt) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSlotNotice {
            return SeasonalSlotNotice(
                code: code,
                label: label,
                startsAt: startsAt,
                sequence: sequence,
                attempts: attempts,
                currency: currency,
                tags: tags,
                quantity: quantity,
                encounterID: encounterID,
                archived: archived,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal slot notice in status open.
    static func newSeasonalSlotNotice(_ code: String, label: String) -> SeasonalSlotNotice {
        return SeasonalSlotNotice(
            code: code,
            label: label,
            startsAt: 0,
            sequence: 0,
            attempts: 0,
            currency: "",
            tags: [],
            quantity: 0,
            encounterID: "",
            archived: false,
            version: 0,
            status: SeasonalSlotNoticeStatus.`open`
        )
    }
}
