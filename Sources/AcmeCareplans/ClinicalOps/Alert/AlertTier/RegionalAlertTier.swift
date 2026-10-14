import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional alert tier is in its life cycle.
    enum RegionalAlertTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a regional alert tier and its current status.
    final class RegionalAlertTier {
        var code: String
        var label: String
        var weight: Double
        var name: String
        var copay: Double
        var cost: Double
        var status: RegionalAlertTierStatus

        init(code: String, label: String, weight: Double, name: String, copay: Double, cost: Double, status: RegionalAlertTierStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.name = name
            self.copay = copay
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalAlertTierStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RegionalAlertTierStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAlertTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional alert tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveLoad() -> Double {
            return ((weight - cost) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAlertTier {
            return RegionalAlertTier(
                code: code,
                label: label,
                weight: weight,
                name: name,
                copay: copay,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional alert tier in status created.
    static func newRegionalAlertTier(_ code: String, label: String) -> RegionalAlertTier {
        return RegionalAlertTier(
            code: code,
            label: label,
            weight: 0.0,
            name: "",
            copay: 0.0,
            cost: 0.0,
            status: RegionalAlertTierStatus.created
        )
    }
}
