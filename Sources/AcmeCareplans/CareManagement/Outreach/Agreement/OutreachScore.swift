import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach score is in its life cycle.
    enum OutreachScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A outreach score. Its code is unique within a tenant.
    final class OutreachScore {
        var code: String
        var label: String
        var discount: Double
        var bed: String
        var clinicianID: String
        var updatedAt: Int
        var graceDays: Int
        var floorValue: Double
        var unit: String
        var amount: Double
        var durationMinutes: Int
        var status: OutreachScoreStatus

        init(code: String, label: String, discount: Double, bed: String, clinicianID: String, updatedAt: Int, graceDays: Int, floorValue: Double, unit: String, amount: Double, durationMinutes: Int, status: OutreachScoreStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.bed = bed
            self.clinicianID = clinicianID
            self.updatedAt = updatedAt
            self.graceDays = graceDays
            self.floorValue = floorValue
            self.unit = unit
            self.amount = amount
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: OutreachScoreStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
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
                return next == OutreachScoreStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveValue() -> Double {
            return (amount * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> OutreachScore {
            return OutreachScore(
                code: code,
                label: label,
                discount: discount,
                bed: bed,
                clinicianID: clinicianID,
                updatedAt: updatedAt,
                graceDays: graceDays,
                floorValue: floorValue,
                unit: unit,
                amount: amount,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a outreach score in status proposed.
    static func newOutreachScore(_ code: String, label: String) -> OutreachScore {
        return OutreachScore(
            code: code,
            label: label,
            discount: 0.0,
            bed: "",
            clinicianID: "",
            updatedAt: 0,
            graceDays: 0,
            floorValue: 0.0,
            unit: "",
            amount: 0.0,
            durationMinutes: 0,
            status: OutreachScoreStatus.proposed
        )
    }
}
