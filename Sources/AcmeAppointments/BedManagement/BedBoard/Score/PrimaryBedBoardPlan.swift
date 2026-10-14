import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary bed board plan is in its life cycle.
    enum PrimaryBedBoardPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary bed board plan as the bed board team keeps it.
    final class PrimaryBedBoardPlan {
        var code: String
        var name: String
        var score: Double
        var unit: String
        var approved: Bool
        var phone: String
        var sequence: Int
        var refills: Int
        var currency: String
        var status: PrimaryBedBoardPlanStatus

        init(code: String, name: String, score: Double, unit: String, approved: Bool, phone: String, sequence: Int, refills: Int, currency: String, status: PrimaryBedBoardPlanStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.unit = unit
            self.approved = approved
            self.phone = phone
            self.sequence = sequence
            self.refills = refills
            self.currency = currency
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

        func canMoveTo(_ next: PrimaryBedBoardPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryBedBoardPlanStatus.withdrawn
            case .approved:
                return next == PrimaryBedBoardPlanStatus.withdrawn
            case .rejected:
                return next == PrimaryBedBoardPlanStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryBedBoardPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary bed board plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(refills) + score) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryBedBoardPlan {
            return PrimaryBedBoardPlan(
                code: code,
                name: name,
                score: score,
                unit: unit,
                approved: approved,
                phone: phone,
                sequence: sequence,
                refills: refills,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary bed board plan in status proposed.
    static func newPrimaryBedBoardPlan(_ code: String, name: String) -> PrimaryBedBoardPlan {
        return PrimaryBedBoardPlan(
            code: code,
            name: name,
            score: 0.0,
            unit: "",
            approved: false,
            phone: "",
            sequence: 0,
            refills: 0,
            currency: "",
            status: PrimaryBedBoardPlanStatus.proposed
        )
    }
}
