import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach variance is in its life cycle.
    enum OutreachVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A outreach variance. Its code is unique within a tenant.
    final class OutreachVariance {
        var code: String
        var name: String
        var approved: Bool
        var graceDays: Int
        var phone: String
        var active: Bool
        var quantity: Int
        var weight: Double
        var limit: Int
        var notes: String
        var status: OutreachVarianceStatus

        init(code: String, name: String, approved: Bool, graceDays: Int, phone: String, active: Bool, quantity: Int, weight: Double, limit: Int, notes: String, status: OutreachVarianceStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.graceDays = graceDays
            self.phone = phone
            self.active = active
            self.quantity = quantity
            self.weight = weight
            self.limit = limit
            self.notes = notes
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

        func canMoveTo(_ next: OutreachVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == OutreachVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("outreach variance") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(limit) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachVariance {
            return OutreachVariance(
                code: code,
                name: name,
                approved: approved,
                graceDays: graceDays,
                phone: phone,
                active: active,
                quantity: quantity,
                weight: weight,
                limit: limit,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a outreach variance in status proposed.
    static func newOutreachVariance(_ code: String, name: String) -> OutreachVariance {
        return OutreachVariance(
            code: code,
            name: name,
            approved: false,
            graceDays: 0,
            phone: "",
            active: false,
            quantity: 0,
            weight: 0.0,
            limit: 0,
            notes: "",
            status: OutreachVarianceStatus.proposed
        )
    }
}
