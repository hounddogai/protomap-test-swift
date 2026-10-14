import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional care gap rule is in its life cycle.
    enum RegionalCareGapRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional care gap rule as the care gap team keeps it.
    final class RegionalCareGapRule {
        var code: String
        var title: String
        var payer: String
        var description: String
        var name: String
        var phone: String
        var copay: Double
        var status: RegionalCareGapRuleStatus

        init(code: String, title: String, payer: String, description: String, name: String, phone: String, copay: Double, status: RegionalCareGapRuleStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.description = description
            self.name = name
            self.phone = phone
            self.copay = copay
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

        func canMoveTo(_ next: RegionalCareGapRuleStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalCareGapRuleStatus.pending || next == RegionalCareGapRuleStatus.active
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RegionalCareGapRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care gap rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> RegionalCareGapRule {
            return RegionalCareGapRule(
                code: code,
                title: title,
                payer: payer,
                description: description,
                name: name,
                phone: phone,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional care gap rule in status draft.
    static func newRegionalCareGapRule(_ code: String, title: String) -> RegionalCareGapRule {
        return RegionalCareGapRule(
            code: code,
            title: title,
            payer: "",
            description: "",
            name: "",
            phone: "",
            copay: 0.0,
            status: RegionalCareGapRuleStatus.draft
        )
    }
}
