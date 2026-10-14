import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped care gap quota is in its life cycle.
    enum CappedCareGapQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a capped care gap quota and its current status.
    final class CappedCareGapQuota {
        var code: String
        var label: String
        var discount: Double
        var unit: String
        var score: Double
        var locale: String
        var ratio: Double
        var country: String
        var floorValue: Double
        var payer: String
        var status: CappedCareGapQuotaStatus

        init(code: String, label: String, discount: Double, unit: String, score: Double, locale: String, ratio: Double, country: String, floorValue: Double, payer: String, status: CappedCareGapQuotaStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.unit = unit
            self.score = score
            self.locale = locale
            self.ratio = ratio
            self.country = country
            self.floorValue = floorValue
            self.payer = payer
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

        func canMoveTo(_ next: CappedCareGapQuotaStatus) -> Bool {
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
                return next == CappedCareGapQuotaStatus.revoked
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

        func moveTo(_ next: CappedCareGapQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care gap quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return ((ratio + score) * 100).rounded() / 100
        }

        func copyValue() -> CappedCareGapQuota {
            return CappedCareGapQuota(
                code: code,
                label: label,
                discount: discount,
                unit: unit,
                score: score,
                locale: locale,
                ratio: ratio,
                country: country,
                floorValue: floorValue,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped care gap quota in status requested.
    static func newCappedCareGapQuota(_ code: String, label: String) -> CappedCareGapQuota {
        return CappedCareGapQuota(
            code: code,
            label: label,
            discount: 0.0,
            unit: "",
            score: 0.0,
            locale: "",
            ratio: 0.0,
            country: "",
            floorValue: 0.0,
            payer: "",
            status: CappedCareGapQuotaStatus.requested
        )
    }
}
