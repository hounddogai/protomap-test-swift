import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network milestone is in its life cycle.
    enum ManualNetworkMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a manual network milestone and its current status.
    final class ManualNetworkMilestone {
        var code: String
        var title: String
        var sequence: Int
        var minimum: Double
        var endsAt: Int
        var diagnosisCode: String
        var externalRef: String
        var reviewer: String
        var contactEmail: String
        var bed: String
        var status: ManualNetworkMilestoneStatus

        init(code: String, title: String, sequence: Int, minimum: Double, endsAt: Int, diagnosisCode: String, externalRef: String, reviewer: String, contactEmail: String, bed: String, status: ManualNetworkMilestoneStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.minimum = minimum
            self.endsAt = endsAt
            self.diagnosisCode = diagnosisCode
            self.externalRef = externalRef
            self.reviewer = reviewer
            self.contactEmail = contactEmail
            self.bed = bed
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

        func canMoveTo(_ next: ManualNetworkMilestoneStatus) -> Bool {
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

        func moveTo(_ next: ManualNetworkMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual network milestone") \(code)"
        }

        func adjustedValue() -> Double {
            return (minimum * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> ManualNetworkMilestone {
            return ManualNetworkMilestone(
                code: code,
                title: title,
                sequence: sequence,
                minimum: minimum,
                endsAt: endsAt,
                diagnosisCode: diagnosisCode,
                externalRef: externalRef,
                reviewer: reviewer,
                contactEmail: contactEmail,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual network milestone in status proposed.
    static func newManualNetworkMilestone(_ code: String, title: String) -> ManualNetworkMilestone {
        return ManualNetworkMilestone(
            code: code,
            title: title,
            sequence: 0,
            minimum: 0.0,
            endsAt: 0,
            diagnosisCode: "",
            externalRef: "",
            reviewer: "",
            contactEmail: "",
            bed: "",
            status: ManualNetworkMilestoneStatus.proposed
        )
    }
}
