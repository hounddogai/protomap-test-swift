import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict proxy baseline is in its life cycle.
    enum StrictProxyBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict proxy baseline. Its code is unique within a tenant.
    final class StrictProxyBaseline {
        var code: String
        var title: String
        var contactEmail: String
        var graceDays: Int
        var refills: Int
        var archived: Bool
        var allergy: String
        var amount: Double
        var status: StrictProxyBaselineStatus

        init(code: String, title: String, contactEmail: String, graceDays: Int, refills: Int, archived: Bool, allergy: String, amount: Double, status: StrictProxyBaselineStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.graceDays = graceDays
            self.refills = refills
            self.archived = archived
            self.allergy = allergy
            self.amount = amount
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

        func canMoveTo(_ next: StrictProxyBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictProxyBaselineStatus.rejected || next == StrictProxyBaselineStatus.withdrawn
            case .approved:
                return next == StrictProxyBaselineStatus.rejected || next == StrictProxyBaselineStatus.withdrawn
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

        func moveTo(_ next: StrictProxyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict proxy baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict proxy baseline") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(refills) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> StrictProxyBaseline {
            return StrictProxyBaseline(
                code: code,
                title: title,
                contactEmail: contactEmail,
                graceDays: graceDays,
                refills: refills,
                archived: archived,
                allergy: allergy,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict proxy baseline in status proposed.
    static func newStrictProxyBaseline(_ code: String, title: String) -> StrictProxyBaseline {
        return StrictProxyBaseline(
            code: code,
            title: title,
            contactEmail: "",
            graceDays: 0,
            refills: 0,
            archived: false,
            allergy: "",
            amount: 0.0,
            status: StrictProxyBaselineStatus.proposed
        )
    }
}
