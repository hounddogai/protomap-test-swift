import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive acuity plan cycle is in its life cycle.
    enum AdaptiveAcuityPlanCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive acuity plan cycle as the acuity plan team keeps it.
    final class AdaptiveAcuityPlanCycle {
        var code: String
        var label: String
        var allergy: String
        var facility: String
        var sequence: Int
        var version: Int
        var retries: Int
        var amount: Double
        var attributes: [String: String]
        var status: AdaptiveAcuityPlanCycleStatus

        init(code: String, label: String, allergy: String, facility: String, sequence: Int, version: Int, retries: Int, amount: Double, attributes: [String: String], status: AdaptiveAcuityPlanCycleStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.facility = facility
            self.sequence = sequence
            self.version = version
            self.retries = retries
            self.amount = amount
            self.attributes = attributes
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

        func canMoveTo(_ next: AdaptiveAcuityPlanCycleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AdaptiveAcuityPlanCycleStatus.suspended
            case .active:
                return next == AdaptiveAcuityPlanCycleStatus.suspended
            case .suspended:
                return next == AdaptiveAcuityPlanCycleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveAcuityPlanCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive acuity plan cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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
            return (amount * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAcuityPlanCycle {
            return AdaptiveAcuityPlanCycle(
                code: code,
                label: label,
                allergy: allergy,
                facility: facility,
                sequence: sequence,
                version: version,
                retries: retries,
                amount: amount,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive acuity plan cycle in status draft.
    static func newAdaptiveAcuityPlanCycle(_ code: String, label: String) -> AdaptiveAcuityPlanCycle {
        return AdaptiveAcuityPlanCycle(
            code: code,
            label: label,
            allergy: "",
            facility: "",
            sequence: 0,
            version: 0,
            retries: 0,
            amount: 0.0,
            attributes: [:],
            status: AdaptiveAcuityPlanCycleStatus.draft
        )
    }
}
