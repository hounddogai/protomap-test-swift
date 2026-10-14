import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding tier is in its life cycle.
    enum RoundingTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a rounding tier and its current status.
    final class RoundingTier {
        var code: String
        var name: String
        var timezone: String
        var threshold: Double
        var phone: String
        var source: String
        var ward: String
        var country: String
        var patientRef: String
        var limit: Int
        var status: RoundingTierStatus

        init(code: String, name: String, timezone: String, threshold: Double, phone: String, source: String, ward: String, country: String, patientRef: String, limit: Int, status: RoundingTierStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.threshold = threshold
            self.phone = phone
            self.source = source
            self.ward = ward
            self.country = country
            self.patientRef = patientRef
            self.limit = limit
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

        func canMoveTo(_ next: RoundingTierStatus) -> Bool {
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
                return next == RoundingTierStatus.rejected || next == RoundingTierStatus.withdrawn
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

        func moveTo(_ next: RoundingTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return ((threshold + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingTier {
            return RoundingTier(
                code: code,
                name: name,
                timezone: timezone,
                threshold: threshold,
                phone: phone,
                source: source,
                ward: ward,
                country: country,
                patientRef: patientRef,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rounding tier in status proposed.
    static func newRoundingTier(_ code: String, name: String) -> RoundingTier {
        return RoundingTier(
            code: code,
            name: name,
            timezone: "",
            threshold: 0.0,
            phone: "",
            source: "",
            ward: "",
            country: "",
            patientRef: "",
            limit: 0,
            status: RoundingTierStatus.proposed
        )
    }
}
