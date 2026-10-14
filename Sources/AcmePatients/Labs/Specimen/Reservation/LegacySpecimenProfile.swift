import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy specimen profile is in its life cycle.
    enum LegacySpecimenProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One legacy specimen profile, with what the planners need to act on it.
    final class LegacySpecimenProfile {
        var code: String
        var label: String
        var cost: Double
        var acuity: Int
        var minimum: Double
        var limit: Int
        var ownerID: String
        var name: String
        var budget: Double
        var clinicianID: String
        var endsAt: Int
        var status: LegacySpecimenProfileStatus

        init(code: String, label: String, cost: Double, acuity: Int, minimum: Double, limit: Int, ownerID: String, name: String, budget: Double, clinicianID: String, endsAt: Int, status: LegacySpecimenProfileStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.acuity = acuity
            self.minimum = minimum
            self.limit = limit
            self.ownerID = ownerID
            self.name = name
            self.budget = budget
            self.clinicianID = clinicianID
            self.endsAt = endsAt
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

        func canMoveTo(_ next: LegacySpecimenProfileStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == LegacySpecimenProfileStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LegacySpecimenProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy specimen profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netExposure() -> Double {
            return ((budget - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacySpecimenProfile {
            return LegacySpecimenProfile(
                code: code,
                label: label,
                cost: cost,
                acuity: acuity,
                minimum: minimum,
                limit: limit,
                ownerID: ownerID,
                name: name,
                budget: budget,
                clinicianID: clinicianID,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy specimen profile in status proposed.
    static func newLegacySpecimenProfile(_ code: String, label: String) -> LegacySpecimenProfile {
        return LegacySpecimenProfile(
            code: code,
            label: label,
            cost: 0.0,
            acuity: 0,
            minimum: 0.0,
            limit: 0,
            ownerID: "",
            name: "",
            budget: 0.0,
            clinicianID: "",
            endsAt: 0,
            status: LegacySpecimenProfileStatus.proposed
        )
    }
}
