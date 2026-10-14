import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient bed board tier is in its life cycle.
    enum LenientBedBoardTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One lenient bed board tier, with what the planners need to act on it.
    final class LenientBedBoardTier {
        var code: String
        var name: String
        var ward: String
        var locale: String
        var country: String
        var endsAt: Int
        var createdAt: Int
        var bed: String
        var weight: Double
        var clinicianID: String
        var maximum: Double
        var status: LenientBedBoardTierStatus

        init(code: String, name: String, ward: String, locale: String, country: String, endsAt: Int, createdAt: Int, bed: String, weight: Double, clinicianID: String, maximum: Double, status: LenientBedBoardTierStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.locale = locale
            self.country = country
            self.endsAt = endsAt
            self.createdAt = createdAt
            self.bed = bed
            self.weight = weight
            self.clinicianID = clinicianID
            self.maximum = maximum
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

        func canMoveTo(_ next: LenientBedBoardTierStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == LenientBedBoardTierStatus.revoked
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

        func moveTo(_ next: LenientBedBoardTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient bed board tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveLoad() -> Double {
            return (weight * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> LenientBedBoardTier {
            return LenientBedBoardTier(
                code: code,
                name: name,
                ward: ward,
                locale: locale,
                country: country,
                endsAt: endsAt,
                createdAt: createdAt,
                bed: bed,
                weight: weight,
                clinicianID: clinicianID,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient bed board tier in status requested.
    static func newLenientBedBoardTier(_ code: String, name: String) -> LenientBedBoardTier {
        return LenientBedBoardTier(
            code: code,
            name: name,
            ward: "",
            locale: "",
            country: "",
            endsAt: 0,
            createdAt: 0,
            bed: "",
            weight: 0.0,
            clinicianID: "",
            maximum: 0.0,
            status: LenientBedBoardTierStatus.requested
        )
    }
}
