import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession mapping is in its life cycle.
    enum AccessionMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A accession mapping. Its code is unique within a tenant.
    final class AccessionMapping {
        var code: String
        var title: String
        var updatedAt: Int
        var externalRef: String
        var rate: Double
        var payer: String
        var threshold: Double
        var attempts: Int
        var acuity: Int
        var specialty: String
        var refills: Int
        var status: AccessionMappingStatus

        init(code: String, title: String, updatedAt: Int, externalRef: String, rate: Double, payer: String, threshold: Double, attempts: Int, acuity: Int, specialty: String, refills: Int, status: AccessionMappingStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.externalRef = externalRef
            self.rate = rate
            self.payer = payer
            self.threshold = threshold
            self.attempts = attempts
            self.acuity = acuity
            self.specialty = specialty
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

        func canMoveTo(_ next: AccessionMappingStatus) -> Bool {
            switch status {
            case .requested:
                return next == AccessionMappingStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: AccessionMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedLoad() -> Double {
            return (rate * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> AccessionMapping {
            return AccessionMapping(
                code: code,
                title: title,
                updatedAt: updatedAt,
                externalRef: externalRef,
                rate: rate,
                payer: payer,
                threshold: threshold,
                attempts: attempts,
                acuity: acuity,
                specialty: specialty,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession mapping in status requested.
    static func newAccessionMapping(_ code: String, title: String) -> AccessionMapping {
        return AccessionMapping(
            code: code,
            title: title,
            updatedAt: 0,
            externalRef: "",
            rate: 0.0,
            payer: "",
            threshold: 0.0,
            attempts: 0,
            acuity: 0,
            specialty: "",
            refills: 0,
            status: AccessionMappingStatus.requested
        )
    }
}
