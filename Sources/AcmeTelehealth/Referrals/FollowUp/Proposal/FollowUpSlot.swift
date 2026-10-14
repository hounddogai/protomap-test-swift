import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up slot is in its life cycle.
    enum FollowUpSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A follow up slot. Its code is unique within a tenant.
    final class FollowUpSlot {
        var code: String
        var title: String
        var maximum: Double
        var attributes: [String: String]
        var refills: Int
        var graceDays: Int
        var status: FollowUpSlotStatus

        init(code: String, title: String, maximum: Double, attributes: [String: String], refills: Int, graceDays: Int, status: FollowUpSlotStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.attributes = attributes
            self.refills = refills
            self.graceDays = graceDays
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

        func canMoveTo(_ next: FollowUpSlotStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == FollowUpSlotStatus.suspended
            case .active:
                return next == FollowUpSlotStatus.suspended || next == FollowUpSlotStatus.closed
            case .suspended:
                return next == FollowUpSlotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("follow up slot") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedVolume() -> Double {
            return ((Double(refills) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpSlot {
            return FollowUpSlot(
                code: code,
                title: title,
                maximum: maximum,
                attributes: attributes,
                refills: refills,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a follow up slot in status draft.
    static func newFollowUpSlot(_ code: String, title: String) -> FollowUpSlot {
        return FollowUpSlot(
            code: code,
            title: title,
            maximum: 0.0,
            attributes: [:],
            refills: 0,
            graceDays: 0,
            status: FollowUpSlotStatus.draft
        )
    }
}
