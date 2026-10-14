import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional slot override is in its life cycle.
    enum RegionalSlotOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional slot override, with what the planners need to act on it.
    final class RegionalSlotOverride {
        var code: String
        var name: String
        var limit: Int
        var facility: String
        var allergy: String
        var specialty: String
        var refills: Int
        var currency: String
        var revision: Int
        var status: RegionalSlotOverrideStatus

        init(code: String, name: String, limit: Int, facility: String, allergy: String, specialty: String, refills: Int, currency: String, revision: Int, status: RegionalSlotOverrideStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.facility = facility
            self.allergy = allergy
            self.specialty = specialty
            self.refills = refills
            self.currency = currency
            self.revision = revision
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

        func canMoveTo(_ next: RegionalSlotOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalSlotOverrideStatus.withdrawn
            case .approved:
                return next == RegionalSlotOverrideStatus.rejected
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

        func moveTo(_ next: RegionalSlotOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional slot override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveExposure() -> Double {
            return ((Double(refills) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSlotOverride {
            return RegionalSlotOverride(
                code: code,
                name: name,
                limit: limit,
                facility: facility,
                allergy: allergy,
                specialty: specialty,
                refills: refills,
                currency: currency,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional slot override in status proposed.
    static func newRegionalSlotOverride(_ code: String, name: String) -> RegionalSlotOverride {
        return RegionalSlotOverride(
            code: code,
            name: name,
            limit: 0,
            facility: "",
            allergy: "",
            specialty: "",
            refills: 0,
            currency: "",
            revision: 0,
            status: RegionalSlotOverrideStatus.proposed
        )
    }
}
