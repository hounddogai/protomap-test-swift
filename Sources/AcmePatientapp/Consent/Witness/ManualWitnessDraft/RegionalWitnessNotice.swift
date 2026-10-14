import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional witness notice is in its life cycle.
    enum RegionalWitnessNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One regional witness notice, with what the planners need to act on it.
    final class RegionalWitnessNotice {
        var code: String
        var label: String
        var clinicianID: String
        var startsAt: Int
        var cost: Double
        var acuity: Int
        var discount: Double
        var status: RegionalWitnessNoticeStatus

        init(code: String, label: String, clinicianID: String, startsAt: Int, cost: Double, acuity: Int, discount: Double, status: RegionalWitnessNoticeStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.startsAt = startsAt
            self.cost = cost
            self.acuity = acuity
            self.discount = discount
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

        func canMoveTo(_ next: RegionalWitnessNoticeStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RegionalWitnessNoticeStatus.revoked || next == RegionalWitnessNoticeStatus.expired
            case .revoked:
                return next == RegionalWitnessNoticeStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalWitnessNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional witness notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("regional witness notice") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(acuity) - cost) * 100).rounded() / 100
        }

        func copyValue() -> RegionalWitnessNotice {
            return RegionalWitnessNotice(
                code: code,
                label: label,
                clinicianID: clinicianID,
                startsAt: startsAt,
                cost: cost,
                acuity: acuity,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional witness notice in status requested.
    static func newRegionalWitnessNotice(_ code: String, label: String) -> RegionalWitnessNotice {
        return RegionalWitnessNotice(
            code: code,
            label: label,
            clinicianID: "",
            startsAt: 0,
            cost: 0.0,
            acuity: 0,
            discount: 0.0,
            status: RegionalWitnessNoticeStatus.requested
        )
    }
}
