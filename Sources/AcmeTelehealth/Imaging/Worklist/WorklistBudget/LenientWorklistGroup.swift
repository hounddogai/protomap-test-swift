import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient worklist group is in its life cycle.
    enum LenientWorklistGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a lenient worklist group and its current status.
    final class LenientWorklistGroup {
        var code: String
        var label: String
        var category: String
        var reviewer: String
        var acuity: Int
        var limit: Int
        var endsAt: Int
        var phone: String
        var visible: Bool
        var maximum: Double
        var quantity: Int
        var status: LenientWorklistGroupStatus

        init(code: String, label: String, category: String, reviewer: String, acuity: Int, limit: Int, endsAt: Int, phone: String, visible: Bool, maximum: Double, quantity: Int, status: LenientWorklistGroupStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.reviewer = reviewer
            self.acuity = acuity
            self.limit = limit
            self.endsAt = endsAt
            self.phone = phone
            self.visible = visible
            self.maximum = maximum
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientWorklistGroupStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientWorklistGroupStatus.revoked || next == LenientWorklistGroupStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LenientWorklistGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient worklist group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("lenient worklist group") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(endsAt) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> LenientWorklistGroup {
            return LenientWorklistGroup(
                code: code,
                label: label,
                category: category,
                reviewer: reviewer,
                acuity: acuity,
                limit: limit,
                endsAt: endsAt,
                phone: phone,
                visible: visible,
                maximum: maximum,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a lenient worklist group in status requested.
    static func newLenientWorklistGroup(_ code: String, label: String) -> LenientWorklistGroup {
        return LenientWorklistGroup(
            code: code,
            label: label,
            category: "",
            reviewer: "",
            acuity: 0,
            limit: 0,
            endsAt: 0,
            phone: "",
            visible: false,
            maximum: 0.0,
            quantity: 0,
            status: LenientWorklistGroupStatus.requested
        )
    }
}
