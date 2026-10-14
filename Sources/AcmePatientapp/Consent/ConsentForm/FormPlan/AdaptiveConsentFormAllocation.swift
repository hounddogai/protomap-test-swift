import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive consent form allocation is in its life cycle.
    enum AdaptiveConsentFormAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive consent form allocation as the consent form team keeps it.
    final class AdaptiveConsentFormAllocation {
        var code: String
        var name: String
        var quantity: Int
        var allergy: String
        var revision: Int
        var active: Bool
        var patientRef: String
        var archived: Bool
        var specialty: String
        var capacity: Int
        var facility: String
        var status: AdaptiveConsentFormAllocationStatus

        init(code: String, name: String, quantity: Int, allergy: String, revision: Int, active: Bool, patientRef: String, archived: Bool, specialty: String, capacity: Int, facility: String, status: AdaptiveConsentFormAllocationStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.allergy = allergy
            self.revision = revision
            self.active = active
            self.patientRef = patientRef
            self.archived = archived
            self.specialty = specialty
            self.capacity = capacity
            self.facility = facility
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

        func canMoveTo(_ next: AdaptiveConsentFormAllocationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AdaptiveConsentFormAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveConsentFormAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive consent form allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveLoad() -> Double {
            return ((Double(revision) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveConsentFormAllocation {
            return AdaptiveConsentFormAllocation(
                code: code,
                name: name,
                quantity: quantity,
                allergy: allergy,
                revision: revision,
                active: active,
                patientRef: patientRef,
                archived: archived,
                specialty: specialty,
                capacity: capacity,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive consent form allocation in status requested.
    static func newAdaptiveConsentFormAllocation(_ code: String, name: String) -> AdaptiveConsentFormAllocation {
        return AdaptiveConsentFormAllocation(
            code: code,
            name: name,
            quantity: 0,
            allergy: "",
            revision: 0,
            active: false,
            patientRef: "",
            archived: false,
            specialty: "",
            capacity: 0,
            facility: "",
            status: AdaptiveConsentFormAllocationStatus.requested
        )
    }
}
