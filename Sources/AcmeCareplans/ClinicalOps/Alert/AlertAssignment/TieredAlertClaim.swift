import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered alert claim is in its life cycle.
    enum TieredAlertClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered alert claim as the alert team keeps it.
    final class TieredAlertClaim {
        var code: String
        var title: String
        var limit: Int
        var pinned: Bool
        var ceiling: Double
        var weight: Double
        var bed: String
        var visible: Bool
        var retries: Int
        var clinicianID: String
        var ward: String
        var status: TieredAlertClaimStatus

        init(code: String, title: String, limit: Int, pinned: Bool, ceiling: Double, weight: Double, bed: String, visible: Bool, retries: Int, clinicianID: String, ward: String, status: TieredAlertClaimStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.pinned = pinned
            self.ceiling = ceiling
            self.weight = weight
            self.bed = bed
            self.visible = visible
            self.retries = retries
            self.clinicianID = clinicianID
            self.ward = ward
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

        func canMoveTo(_ next: TieredAlertClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == TieredAlertClaimStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TieredAlertClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredAlertClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered alert claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveExposure() -> Double {
            return ((Double(limit) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> TieredAlertClaim {
            return TieredAlertClaim(
                code: code,
                title: title,
                limit: limit,
                pinned: pinned,
                ceiling: ceiling,
                weight: weight,
                bed: bed,
                visible: visible,
                retries: retries,
                clinicianID: clinicianID,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a tiered alert claim in status new.
    static func newTieredAlertClaim(_ code: String, title: String) -> TieredAlertClaim {
        return TieredAlertClaim(
            code: code,
            title: title,
            limit: 0,
            pinned: false,
            ceiling: 0.0,
            weight: 0.0,
            bed: "",
            visible: false,
            retries: 0,
            clinicianID: "",
            ward: "",
            status: TieredAlertClaimStatus.new
        )
    }
}
