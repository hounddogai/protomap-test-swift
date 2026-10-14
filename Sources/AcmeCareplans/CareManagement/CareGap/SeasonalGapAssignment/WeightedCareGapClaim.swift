import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted care gap claim is in its life cycle.
    enum WeightedCareGapClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One weighted care gap claim, with what the planners need to act on it.
    final class WeightedCareGapClaim {
        var code: String
        var label: String
        var graceDays: Int
        var region: String
        var expiresAt: Int
        var windowDays: Int
        var pinned: Bool
        var unit: String
        var locale: String
        var visible: Bool
        var status: WeightedCareGapClaimStatus

        init(code: String, label: String, graceDays: Int, region: String, expiresAt: Int, windowDays: Int, pinned: Bool, unit: String, locale: String, visible: Bool, status: WeightedCareGapClaimStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.region = region
            self.expiresAt = expiresAt
            self.windowDays = windowDays
            self.pinned = pinned
            self.unit = unit
            self.locale = locale
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedCareGapClaimStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WeightedCareGapClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted care gap claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return (Double(graceDays) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCareGapClaim {
            return WeightedCareGapClaim(
                code: code,
                label: label,
                graceDays: graceDays,
                region: region,
                expiresAt: expiresAt,
                windowDays: windowDays,
                pinned: pinned,
                unit: unit,
                locale: locale,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted care gap claim in status created.
    static func newWeightedCareGapClaim(_ code: String, label: String) -> WeightedCareGapClaim {
        return WeightedCareGapClaim(
            code: code,
            label: label,
            graceDays: 0,
            region: "",
            expiresAt: 0,
            windowDays: 0,
            pinned: false,
            unit: "",
            locale: "",
            visible: false,
            status: WeightedCareGapClaimStatus.created
        )
    }
}
