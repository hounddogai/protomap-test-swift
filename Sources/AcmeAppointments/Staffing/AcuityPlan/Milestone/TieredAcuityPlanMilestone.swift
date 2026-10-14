import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered acuity plan milestone is in its life cycle.
    enum TieredAcuityPlanMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One tiered acuity plan milestone, with what the planners need to act on it.
    final class TieredAcuityPlanMilestone {
        var code: String
        var name: String
        var createdAt: Int
        var margin: Double
        var ward: String
        var procedureCode: String
        var notes: String
        var attributes: [String: String]
        var status: TieredAcuityPlanMilestoneStatus

        init(code: String, name: String, createdAt: Int, margin: Double, ward: String, procedureCode: String, notes: String, attributes: [String: String], status: TieredAcuityPlanMilestoneStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.margin = margin
            self.ward = ward
            self.procedureCode = procedureCode
            self.notes = notes
            self.attributes = attributes
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

        func canMoveTo(_ next: TieredAcuityPlanMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredAcuityPlanMilestoneStatus.rejected || next == TieredAcuityPlanMilestoneStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == TieredAcuityPlanMilestoneStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredAcuityPlanMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered acuity plan milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func adjustedTotal() -> Double {
            return ((margin + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredAcuityPlanMilestone {
            return TieredAcuityPlanMilestone(
                code: code,
                name: name,
                createdAt: createdAt,
                margin: margin,
                ward: ward,
                procedureCode: procedureCode,
                notes: notes,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a tiered acuity plan milestone in status proposed.
    static func newTieredAcuityPlanMilestone(_ code: String, name: String) -> TieredAcuityPlanMilestone {
        return TieredAcuityPlanMilestone(
            code: code,
            name: name,
            createdAt: 0,
            margin: 0.0,
            ward: "",
            procedureCode: "",
            notes: "",
            attributes: [:],
            status: TieredAcuityPlanMilestoneStatus.proposed
        )
    }
}
