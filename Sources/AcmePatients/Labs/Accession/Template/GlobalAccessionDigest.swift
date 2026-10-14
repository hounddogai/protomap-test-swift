import AcmePlatform
import Foundation

extension Labs {
    /// Where a global accession digest is in its life cycle.
    enum GlobalAccessionDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global accession digest as the accession team keeps it.
    final class GlobalAccessionDigest {
        var code: String
        var name: String
        var locale: String
        var capacity: Int
        var graceDays: Int
        var rate: Double
        var budget: Double
        var limit: Int
        var specialty: String
        var diagnosisCode: String
        var status: GlobalAccessionDigestStatus

        init(code: String, name: String, locale: String, capacity: Int, graceDays: Int, rate: Double, budget: Double, limit: Int, specialty: String, diagnosisCode: String, status: GlobalAccessionDigestStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.capacity = capacity
            self.graceDays = graceDays
            self.rate = rate
            self.budget = budget
            self.limit = limit
            self.specialty = specialty
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: GlobalAccessionDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalAccessionDigestStatus.granted || next == GlobalAccessionDigestStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == GlobalAccessionDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalAccessionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global accession digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global accession digest") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((budget + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalAccessionDigest {
            return GlobalAccessionDigest(
                code: code,
                name: name,
                locale: locale,
                capacity: capacity,
                graceDays: graceDays,
                rate: rate,
                budget: budget,
                limit: limit,
                specialty: specialty,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global accession digest in status requested.
    static func newGlobalAccessionDigest(_ code: String, name: String) -> GlobalAccessionDigest {
        return GlobalAccessionDigest(
            code: code,
            name: name,
            locale: "",
            capacity: 0,
            graceDays: 0,
            rate: 0.0,
            budget: 0.0,
            limit: 0,
            specialty: "",
            diagnosisCode: "",
            status: GlobalAccessionDigestStatus.requested
        )
    }
}
