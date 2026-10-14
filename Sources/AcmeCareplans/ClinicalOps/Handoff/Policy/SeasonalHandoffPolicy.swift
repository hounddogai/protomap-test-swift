import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal handoff policy is in its life cycle.
    enum SeasonalHandoffPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A seasonal handoff policy. Its code is unique within a tenant.
    final class SeasonalHandoffPolicy {
        var code: String
        var name: String
        var ward: String
        var visible: Bool
        var amount: Double
        var facility: String
        var encounterID: String
        var discount: Double
        var clinicianID: String
        var specialty: String
        var budget: Double
        var status: SeasonalHandoffPolicyStatus

        init(code: String, name: String, ward: String, visible: Bool, amount: Double, facility: String, encounterID: String, discount: Double, clinicianID: String, specialty: String, budget: Double, status: SeasonalHandoffPolicyStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.visible = visible
            self.amount = amount
            self.facility = facility
            self.encounterID = encounterID
            self.discount = discount
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalHandoffPolicyStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalHandoffPolicyStatus.cancelled
            case .scheduled:
                return next == SeasonalHandoffPolicyStatus.completed
            case .inProgress:
                return next == SeasonalHandoffPolicyStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SeasonalHandoffPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal handoff policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal handoff policy") \(code)"
        }

        func adjustedExposure() -> Double {
            return (amount * budget * 100).rounded() / 100
        }

        func copyValue() -> SeasonalHandoffPolicy {
            return SeasonalHandoffPolicy(
                code: code,
                name: name,
                ward: ward,
                visible: visible,
                amount: amount,
                facility: facility,
                encounterID: encounterID,
                discount: discount,
                clinicianID: clinicianID,
                specialty: specialty,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a seasonal handoff policy in status planned.
    static func newSeasonalHandoffPolicy(_ code: String, name: String) -> SeasonalHandoffPolicy {
        return SeasonalHandoffPolicy(
            code: code,
            name: name,
            ward: "",
            visible: false,
            amount: 0.0,
            facility: "",
            encounterID: "",
            discount: 0.0,
            clinicianID: "",
            specialty: "",
            budget: 0.0,
            status: SeasonalHandoffPolicyStatus.planned
        )
    }
}
