import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional closure claim is in its life cycle.
    enum RegionalClosureClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One regional closure claim, with what the planners need to act on it.
    final class RegionalClosureClaim {
        var code: String
        var title: String
        var patientRef: String
        var channel: String
        var sequence: Int
        var payer: String
        var dosageMg: Double
        var endsAt: Int
        var copay: Double
        var status: RegionalClosureClaimStatus

        init(code: String, title: String, patientRef: String, channel: String, sequence: Int, payer: String, dosageMg: Double, endsAt: Int, copay: Double, status: RegionalClosureClaimStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.channel = channel
            self.sequence = sequence
            self.payer = payer
            self.dosageMg = dosageMg
            self.endsAt = endsAt
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalClosureClaimStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalClosureClaimStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RegionalClosureClaimStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalClosureClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional closure claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedLoad() -> Double {
            return ((dosageMg - copay) * 100).rounded() / 100
        }

        func copyValue() -> RegionalClosureClaim {
            return RegionalClosureClaim(
                code: code,
                title: title,
                patientRef: patientRef,
                channel: channel,
                sequence: sequence,
                payer: payer,
                dosageMg: dosageMg,
                endsAt: endsAt,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a regional closure claim in status open.
    static func newRegionalClosureClaim(_ code: String, title: String) -> RegionalClosureClaim {
        return RegionalClosureClaim(
            code: code,
            title: title,
            patientRef: "",
            channel: "",
            sequence: 0,
            payer: "",
            dosageMg: 0.0,
            endsAt: 0,
            copay: 0.0,
            status: RegionalClosureClaimStatus.`open`
        )
    }
}
