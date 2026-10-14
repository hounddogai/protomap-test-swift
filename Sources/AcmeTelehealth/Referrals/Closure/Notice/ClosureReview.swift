import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure review is in its life cycle.
    enum ClosureReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A closure review as the closure team keeps it.
    final class ClosureReview {
        var code: String
        var name: String
        var encounterID: String
        var expiresAt: Int
        var margin: Double
        var visible: Bool
        var discount: Double
        var budget: Double
        var endsAt: Int
        var phone: String
        var source: String
        var status: ClosureReviewStatus

        init(code: String, name: String, encounterID: String, expiresAt: Int, margin: Double, visible: Bool, discount: Double, budget: Double, endsAt: Int, phone: String, source: String, status: ClosureReviewStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.expiresAt = expiresAt
            self.margin = margin
            self.visible = visible
            self.discount = discount
            self.budget = budget
            self.endsAt = endsAt
            self.phone = phone
            self.source = source
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

        func canMoveTo(_ next: ClosureReviewStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ClosureReviewStatus.approved || next == ClosureReviewStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ClosureReviewStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return (budget * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> ClosureReview {
            return ClosureReview(
                code: code,
                name: name,
                encounterID: encounterID,
                expiresAt: expiresAt,
                margin: margin,
                visible: visible,
                discount: discount,
                budget: budget,
                endsAt: endsAt,
                phone: phone,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a closure review in status proposed.
    static func newClosureReview(_ code: String, name: String) -> ClosureReview {
        return ClosureReview(
            code: code,
            name: name,
            encounterID: "",
            expiresAt: 0,
            margin: 0.0,
            visible: false,
            discount: 0.0,
            budget: 0.0,
            endsAt: 0,
            phone: "",
            source: "",
            status: ClosureReviewStatus.proposed
        )
    }
}
