import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted order set rule is in its life cycle.
    enum WeightedOrderSetRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted order set rule as the order set team keeps it.
    final class WeightedOrderSetRule {
        var code: String
        var name: String
        var refills: Int
        var updatedAt: Int
        var label: String
        var specialty: String
        var notes: String
        var status: WeightedOrderSetRuleStatus

        init(code: String, name: String, refills: Int, updatedAt: Int, label: String, specialty: String, notes: String, status: WeightedOrderSetRuleStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.updatedAt = updatedAt
            self.label = label
            self.specialty = specialty
            self.notes = notes
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

        func canMoveTo(_ next: WeightedOrderSetRuleStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedOrderSetRuleStatus.revoked
            case .granted:
                return next == WeightedOrderSetRuleStatus.revoked
            case .revoked:
                return next == WeightedOrderSetRuleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedOrderSetRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted order set rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return ((Double(updatedAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedOrderSetRule {
            return WeightedOrderSetRule(
                code: code,
                name: name,
                refills: refills,
                updatedAt: updatedAt,
                label: label,
                specialty: specialty,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted order set rule in status requested.
    static func newWeightedOrderSetRule(_ code: String, name: String) -> WeightedOrderSetRule {
        return WeightedOrderSetRule(
            code: code,
            name: name,
            refills: 0,
            updatedAt: 0,
            label: "",
            specialty: "",
            notes: "",
            status: WeightedOrderSetRuleStatus.requested
        )
    }
}
