import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall plan is in its life cycle.
    enum RecallPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One recall plan, with what the planners need to act on it.
    final class RecallPlan {
        var code: String
        var title: String
        var pinned: Bool
        var ownerID: String
        var discount: Double
        var capacity: Int
        var attributes: [String: String]
        var floorValue: Double
        var graceDays: Int
        var expiresAt: Int
        var status: RecallPlanStatus

        init(code: String, title: String, pinned: Bool, ownerID: String, discount: Double, capacity: Int, attributes: [String: String], floorValue: Double, graceDays: Int, expiresAt: Int, status: RecallPlanStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.ownerID = ownerID
            self.discount = discount
            self.capacity = capacity
            self.attributes = attributes
            self.floorValue = floorValue
            self.graceDays = graceDays
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RecallPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RecallPlanStatus.rejected
            case .approved:
                return next == RecallPlanStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RecallPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("recall plan") \(code)"
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

        func adjustedValue() -> Double {
            return ((Double(expiresAt) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RecallPlan {
            return RecallPlan(
                code: code,
                title: title,
                pinned: pinned,
                ownerID: ownerID,
                discount: discount,
                capacity: capacity,
                attributes: attributes,
                floorValue: floorValue,
                graceDays: graceDays,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a recall plan in status proposed.
    static func newRecallPlan(_ code: String, title: String) -> RecallPlan {
        return RecallPlan(
            code: code,
            title: title,
            pinned: false,
            ownerID: "",
            discount: 0.0,
            capacity: 0,
            attributes: [:],
            floorValue: 0.0,
            graceDays: 0,
            expiresAt: 0,
            status: RecallPlanStatus.proposed
        )
    }
}
