import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan request is in its life cycle.
    enum DischargePlanRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a discharge plan request and its current status.
    final class DischargePlanRequest {
        var code: String
        var name: String
        var active: Bool
        var retries: Int
        var budget: Double
        var contactEmail: String
        var batchSize: Int
        var clinicianID: String
        var status: DischargePlanRequestStatus

        init(code: String, name: String, active: Bool, retries: Int, budget: Double, contactEmail: String, batchSize: Int, clinicianID: String, status: DischargePlanRequestStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.retries = retries
            self.budget = budget
            self.contactEmail = contactEmail
            self.batchSize = batchSize
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: DischargePlanRequestStatus) -> Bool {
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
                case .withdrawn:
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

        func moveTo(_ next: DischargePlanRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netVolume() -> Double {
            return ((Double(retries) + budget) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanRequest {
            return DischargePlanRequest(
                code: code,
                name: name,
                active: active,
                retries: retries,
                budget: budget,
                contactEmail: contactEmail,
                batchSize: batchSize,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a discharge plan request in status proposed.
    static func newDischargePlanRequest(_ code: String, name: String) -> DischargePlanRequest {
        return DischargePlanRequest(
            code: code,
            name: name,
            active: false,
            retries: 0,
            budget: 0.0,
            contactEmail: "",
            batchSize: 0,
            clinicianID: "",
            status: DischargePlanRequestStatus.proposed
        )
    }
}
