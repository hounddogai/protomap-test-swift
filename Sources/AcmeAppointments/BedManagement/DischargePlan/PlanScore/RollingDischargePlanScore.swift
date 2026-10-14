import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling discharge plan score is in its life cycle.
    enum RollingDischargePlanScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a rolling discharge plan score and its current status.
    final class RollingDischargePlanScore {
        var code: String
        var title: String
        var refills: Int
        var payer: String
        var bed: String
        var contactEmail: String
        var status: RollingDischargePlanScoreStatus

        init(code: String, title: String, refills: Int, payer: String, bed: String, contactEmail: String, status: RollingDischargePlanScoreStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.payer = payer
            self.bed = bed
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: RollingDischargePlanScoreStatus) -> Bool {
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
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RollingDischargePlanScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling discharge plan score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> RollingDischargePlanScore {
            return RollingDischargePlanScore(
                code: code,
                title: title,
                refills: refills,
                payer: payer,
                bed: bed,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling discharge plan score in status requested.
    static func newRollingDischargePlanScore(_ code: String, title: String) -> RollingDischargePlanScore {
        return RollingDischargePlanScore(
            code: code,
            title: title,
            refills: 0,
            payer: "",
            bed: "",
            contactEmail: "",
            status: RollingDischargePlanScoreStatus.requested
        )
    }
}
