import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen digest is in its life cycle.
    enum SpecimenDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a specimen digest and its current status.
    final class SpecimenDigest {
        var code: String
        var name: String
        var acuity: Int
        var budget: Double
        var timezone: String
        var encounterID: String
        var status: SpecimenDigestStatus

        init(code: String, name: String, acuity: Int, budget: Double, timezone: String, encounterID: String, status: SpecimenDigestStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.budget = budget
            self.timezone = timezone
            self.encounterID = encounterID
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

        func canMoveTo(_ next: SpecimenDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SpecimenDigestStatus.approved || next == SpecimenDigestStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SpecimenDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return (budget * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenDigest {
            return SpecimenDigest(
                code: code,
                name: name,
                acuity: acuity,
                budget: budget,
                timezone: timezone,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a specimen digest in status proposed.
    static func newSpecimenDigest(_ code: String, name: String) -> SpecimenDigest {
        return SpecimenDigest(
            code: code,
            name: name,
            acuity: 0,
            budget: 0.0,
            timezone: "",
            encounterID: "",
            status: SpecimenDigestStatus.proposed
        )
    }
}
