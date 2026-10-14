import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap rule is in its life cycle.
    enum CareGapRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A care gap rule as the care gap team keeps it.
    final class CareGapRule {
        var code: String
        var name: String
        var quantity: Int
        var version: Int
        var checksum: String
        var discount: Double
        var bed: String
        var status: CareGapRuleStatus

        init(code: String, name: String, quantity: Int, version: Int, checksum: String, discount: Double, bed: String, status: CareGapRuleStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.version = version
            self.checksum = checksum
            self.discount = discount
            self.bed = bed
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

        func canMoveTo(_ next: CareGapRuleStatus) -> Bool {
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
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CareGapRuleStatus.reopened || next == CareGapRuleStatus.archived
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

        func moveTo(_ next: CareGapRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("care gap rule") \(code)"
        }

        func projectedValue() -> Double {
            return ((discount - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapRule {
            return CareGapRule(
                code: code,
                name: name,
                quantity: quantity,
                version: version,
                checksum: checksum,
                discount: discount,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care gap rule in status open.
    static func newCareGapRule(_ code: String, name: String) -> CareGapRule {
        return CareGapRule(
            code: code,
            name: name,
            quantity: 0,
            version: 0,
            checksum: "",
            discount: 0.0,
            bed: "",
            status: CareGapRuleStatus.`open`
        )
    }
}
