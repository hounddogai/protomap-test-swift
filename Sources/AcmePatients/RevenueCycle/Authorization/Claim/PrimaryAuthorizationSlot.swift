import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary authorization slot is in its life cycle.
    enum PrimaryAuthorizationSlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary authorization slot. Its code is unique within a tenant.
    final class PrimaryAuthorizationSlot {
        var code: String
        var title: String
        var durationMinutes: Int
        var unit: String
        var country: String
        var phone: String
        var limit: Int
        var status: PrimaryAuthorizationSlotStatus

        init(code: String, title: String, durationMinutes: Int, unit: String, country: String, phone: String, limit: Int, status: PrimaryAuthorizationSlotStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.unit = unit
            self.country = country
            self.phone = phone
            self.limit = limit
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

        func canMoveTo(_ next: PrimaryAuthorizationSlotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PrimaryAuthorizationSlotStatus.resolved
            case .resolved:
                return next == PrimaryAuthorizationSlotStatus.archived
            case .reopened:
                return next == PrimaryAuthorizationSlotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryAuthorizationSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary authorization slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveValue() -> Double {
            return ((Double(limit) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAuthorizationSlot {
            return PrimaryAuthorizationSlot(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                unit: unit,
                country: country,
                phone: phone,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary authorization slot in status open.
    static func newPrimaryAuthorizationSlot(_ code: String, title: String) -> PrimaryAuthorizationSlot {
        return PrimaryAuthorizationSlot(
            code: code,
            title: title,
            durationMinutes: 0,
            unit: "",
            country: "",
            phone: "",
            limit: 0,
            status: PrimaryAuthorizationSlotStatus.`open`
        )
    }
}
