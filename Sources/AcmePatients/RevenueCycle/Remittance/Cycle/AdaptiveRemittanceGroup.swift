import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive remittance group is in its life cycle.
    enum AdaptiveRemittanceGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One adaptive remittance group, with what the planners need to act on it.
    final class AdaptiveRemittanceGroup {
        var code: String
        var title: String
        var graceDays: Int
        var ceiling: Double
        var allergy: String
        var floorValue: Double
        var ward: String
        var status: AdaptiveRemittanceGroupStatus

        init(code: String, title: String, graceDays: Int, ceiling: Double, allergy: String, floorValue: Double, ward: String, status: AdaptiveRemittanceGroupStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.ceiling = ceiling
            self.allergy = allergy
            self.floorValue = floorValue
            self.ward = ward
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

        func canMoveTo(_ next: AdaptiveRemittanceGroupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveRemittanceGroupStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveRemittanceGroupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRemittanceGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive remittance group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive remittance group") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(graceDays) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRemittanceGroup {
            return AdaptiveRemittanceGroup(
                code: code,
                title: title,
                graceDays: graceDays,
                ceiling: ceiling,
                allergy: allergy,
                floorValue: floorValue,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive remittance group in status proposed.
    static func newAdaptiveRemittanceGroup(_ code: String, title: String) -> AdaptiveRemittanceGroup {
        return AdaptiveRemittanceGroup(
            code: code,
            title: title,
            graceDays: 0,
            ceiling: 0.0,
            allergy: "",
            floorValue: 0.0,
            ward: "",
            status: AdaptiveRemittanceGroupStatus.proposed
        )
    }
}
