import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped study slot is in its life cycle.
    enum CappedStudySlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One capped study slot, with what the planners need to act on it.
    final class CappedStudySlot {
        var code: String
        var title: String
        var attempts: Int
        var acuity: Int
        var margin: Double
        var tags: [String]
        var status: CappedStudySlotStatus

        init(code: String, title: String, attempts: Int, acuity: Int, margin: Double, tags: [String], status: CappedStudySlotStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.acuity = acuity
            self.margin = margin
            self.tags = tags
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

        func canMoveTo(_ next: CappedStudySlotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CappedStudySlotStatus.archived
            case .resolved:
                return next == CappedStudySlotStatus.reopened || next == CappedStudySlotStatus.archived
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

        func moveTo(_ next: CappedStudySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped study slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((margin + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedStudySlot {
            return CappedStudySlot(
                code: code,
                title: title,
                attempts: attempts,
                acuity: acuity,
                margin: margin,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped study slot in status open.
    static func newCappedStudySlot(_ code: String, title: String) -> CappedStudySlot {
        return CappedStudySlot(
            code: code,
            title: title,
            attempts: 0,
            acuity: 0,
            margin: 0.0,
            tags: [],
            status: CappedStudySlotStatus.`open`
        )
    }
}
