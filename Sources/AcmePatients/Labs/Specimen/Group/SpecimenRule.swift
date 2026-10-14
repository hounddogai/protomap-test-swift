import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen rule is in its life cycle.
    enum SpecimenRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A specimen rule as the specimen team keeps it.
    final class SpecimenRule {
        var code: String
        var title: String
        var label: String
        var amount: Double
        var approved: Bool
        var cost: Double
        var region: String
        var ward: String
        var expiresAt: Int
        var status: SpecimenRuleStatus

        init(code: String, title: String, label: String, amount: Double, approved: Bool, cost: Double, region: String, ward: String, expiresAt: Int, status: SpecimenRuleStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.amount = amount
            self.approved = approved
            self.cost = cost
            self.region = region
            self.ward = ward
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SpecimenRuleStatus.done || next == SpecimenRuleStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SpecimenRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return ((cost + amount) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenRule {
            return SpecimenRule(
                code: code,
                title: title,
                label: label,
                amount: amount,
                approved: approved,
                cost: cost,
                region: region,
                ward: ward,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a specimen rule in status new.
    static func newSpecimenRule(_ code: String, title: String) -> SpecimenRule {
        return SpecimenRule(
            code: code,
            title: title,
            label: "",
            amount: 0.0,
            approved: false,
            cost: 0.0,
            region: "",
            ward: "",
            expiresAt: 0,
            status: SpecimenRuleStatus.new
        )
    }
}
