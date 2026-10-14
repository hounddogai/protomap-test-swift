import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral assignment is in its life cycle.
    enum ReferralAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a referral assignment and its current status.
    final class ReferralAssignment {
        var code: String
        var title: String
        var name: String
        var patientRef: String
        var segment: String
        var country: String
        var unit: String
        var procedureCode: String
        var amount: Double
        var status: ReferralAssignmentStatus

        init(code: String, title: String, name: String, patientRef: String, segment: String, country: String, unit: String, procedureCode: String, amount: Double, status: ReferralAssignmentStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.patientRef = patientRef
            self.segment = segment
            self.country = country
            self.unit = unit
            self.procedureCode = procedureCode
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralAssignmentStatus) -> Bool {
            switch status {
            case .new:
                return next == ReferralAssignmentStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ReferralAssignmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> ReferralAssignment {
            return ReferralAssignment(
                code: code,
                title: title,
                name: name,
                patientRef: patientRef,
                segment: segment,
                country: country,
                unit: unit,
                procedureCode: procedureCode,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a referral assignment in status new.
    static func newReferralAssignment(_ code: String, title: String) -> ReferralAssignment {
        return ReferralAssignment(
            code: code,
            title: title,
            name: "",
            patientRef: "",
            segment: "",
            country: "",
            unit: "",
            procedureCode: "",
            amount: 0.0,
            status: ReferralAssignmentStatus.new
        )
    }
}
