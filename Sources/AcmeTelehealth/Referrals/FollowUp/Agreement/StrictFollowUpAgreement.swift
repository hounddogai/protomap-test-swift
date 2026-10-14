import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict follow up agreement is in its life cycle.
    enum StrictFollowUpAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a strict follow up agreement and its current status.
    final class StrictFollowUpAgreement {
        var code: String
        var name: String
        var pinned: Bool
        var facility: String
        var acuity: Int
        var diagnosisCode: String
        var amount: Double
        var ownerID: String
        var windowDays: Int
        var createdAt: Int
        var status: StrictFollowUpAgreementStatus

        init(code: String, name: String, pinned: Bool, facility: String, acuity: Int, diagnosisCode: String, amount: Double, ownerID: String, windowDays: Int, createdAt: Int, status: StrictFollowUpAgreementStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.facility = facility
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
            self.amount = amount
            self.ownerID = ownerID
            self.windowDays = windowDays
            self.createdAt = createdAt
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

        func canMoveTo(_ next: StrictFollowUpAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: StrictFollowUpAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict follow up agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return (amount * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> StrictFollowUpAgreement {
            return StrictFollowUpAgreement(
                code: code,
                name: name,
                pinned: pinned,
                facility: facility,
                acuity: acuity,
                diagnosisCode: diagnosisCode,
                amount: amount,
                ownerID: ownerID,
                windowDays: windowDays,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a strict follow up agreement in status proposed.
    static func newStrictFollowUpAgreement(_ code: String, name: String) -> StrictFollowUpAgreement {
        return StrictFollowUpAgreement(
            code: code,
            name: name,
            pinned: false,
            facility: "",
            acuity: 0,
            diagnosisCode: "",
            amount: 0.0,
            ownerID: "",
            windowDays: 0,
            createdAt: 0,
            status: StrictFollowUpAgreementStatus.proposed
        )
    }
}
