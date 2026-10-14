import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback remittance bundle is in its life cycle.
    enum FallbackRemittanceBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a fallback remittance bundle and its current status.
    final class FallbackRemittanceBundle {
        var code: String
        var label: String
        var encounterID: String
        var clinicianID: String
        var floorValue: Double
        var title: String
        var limit: Int
        var category: String
        var timezone: String
        var rate: Double
        var status: FallbackRemittanceBundleStatus

        init(code: String, label: String, encounterID: String, clinicianID: String, floorValue: Double, title: String, limit: Int, category: String, timezone: String, rate: Double, status: FallbackRemittanceBundleStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.title = title
            self.limit = limit
            self.category = category
            self.timezone = timezone
            self.rate = rate
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

        func canMoveTo(_ next: FallbackRemittanceBundleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FallbackRemittanceBundleStatus.rejected || next == FallbackRemittanceBundleStatus.withdrawn
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

        func moveTo(_ next: FallbackRemittanceBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback remittance bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback remittance bundle") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((rate + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRemittanceBundle {
            return FallbackRemittanceBundle(
                code: code,
                label: label,
                encounterID: encounterID,
                clinicianID: clinicianID,
                floorValue: floorValue,
                title: title,
                limit: limit,
                category: category,
                timezone: timezone,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback remittance bundle in status proposed.
    static func newFallbackRemittanceBundle(_ code: String, label: String) -> FallbackRemittanceBundle {
        return FallbackRemittanceBundle(
            code: code,
            label: label,
            encounterID: "",
            clinicianID: "",
            floorValue: 0.0,
            title: "",
            limit: 0,
            category: "",
            timezone: "",
            rate: 0.0,
            status: FallbackRemittanceBundleStatus.proposed
        )
    }
}
