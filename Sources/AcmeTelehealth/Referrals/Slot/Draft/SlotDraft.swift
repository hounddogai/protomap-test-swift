import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot draft is in its life cycle.
    enum SlotDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One slot draft, with what the planners need to act on it.
    final class SlotDraft {
        var code: String
        var label: String
        var windowDays: Int
        var createdAt: Int
        var startsAt: Int
        var locale: String
        var ceiling: Double
        var cost: Double
        var segment: String
        var ratio: Double
        var status: SlotDraftStatus

        init(code: String, label: String, windowDays: Int, createdAt: Int, startsAt: Int, locale: String, ceiling: Double, cost: Double, segment: String, ratio: Double, status: SlotDraftStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.locale = locale
            self.ceiling = ceiling
            self.cost = cost
            self.segment = segment
            self.ratio = ratio
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

        func canMoveTo(_ next: SlotDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == SlotDraftStatus.resolved || next == SlotDraftStatus.archived
            case .resolved:
                return next == SlotDraftStatus.reopened
            case .reopened:
                return next == SlotDraftStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("slot draft") \(code)"
        }

        func weightedExposure() -> Double {
            return ((ratio + cost) * 100).rounded() / 100
        }

        func copyValue() -> SlotDraft {
            return SlotDraft(
                code: code,
                label: label,
                windowDays: windowDays,
                createdAt: createdAt,
                startsAt: startsAt,
                locale: locale,
                ceiling: ceiling,
                cost: cost,
                segment: segment,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a slot draft in status open.
    static func newSlotDraft(_ code: String, label: String) -> SlotDraft {
        return SlotDraft(
            code: code,
            label: label,
            windowDays: 0,
            createdAt: 0,
            startsAt: 0,
            locale: "",
            ceiling: 0.0,
            cost: 0.0,
            segment: "",
            ratio: 0.0,
            status: SlotDraftStatus.`open`
        )
    }
}
