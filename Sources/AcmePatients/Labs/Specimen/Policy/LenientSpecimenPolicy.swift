import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient specimen policy is in its life cycle.
    enum LenientSpecimenPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient specimen policy as the specimen team keeps it.
    final class LenientSpecimenPolicy {
        var code: String
        var title: String
        var bed: String
        var phone: String
        var startsAt: Int
        var limit: Int
        var minimum: Double
        var acuity: Int
        var refills: Int
        var status: LenientSpecimenPolicyStatus

        init(code: String, title: String, bed: String, phone: String, startsAt: Int, limit: Int, minimum: Double, acuity: Int, refills: Int, status: LenientSpecimenPolicyStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.phone = phone
            self.startsAt = startsAt
            self.limit = limit
            self.minimum = minimum
            self.acuity = acuity
            self.refills = refills
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

        func canMoveTo(_ next: LenientSpecimenPolicyStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientSpecimenPolicyStatus.granted || next == LenientSpecimenPolicyStatus.expired
            case .granted:
                return next == LenientSpecimenPolicyStatus.revoked || next == LenientSpecimenPolicyStatus.expired
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

        func moveTo(_ next: LenientSpecimenPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient specimen policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient specimen policy") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(acuity) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> LenientSpecimenPolicy {
            return LenientSpecimenPolicy(
                code: code,
                title: title,
                bed: bed,
                phone: phone,
                startsAt: startsAt,
                limit: limit,
                minimum: minimum,
                acuity: acuity,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient specimen policy in status requested.
    static func newLenientSpecimenPolicy(_ code: String, title: String) -> LenientSpecimenPolicy {
        return LenientSpecimenPolicy(
            code: code,
            title: title,
            bed: "",
            phone: "",
            startsAt: 0,
            limit: 0,
            minimum: 0.0,
            acuity: 0,
            refills: 0,
            status: LenientSpecimenPolicyStatus.requested
        )
    }
}
