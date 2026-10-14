import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive statement profile is in its life cycle.
    enum AdaptiveStatementProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive statement profile as the statement team keeps it.
    final class AdaptiveStatementProfile {
        var code: String
        var label: String
        var windowDays: Int
        var facility: String
        var quantity: Int
        var status: AdaptiveStatementProfileStatus

        init(code: String, label: String, windowDays: Int, facility: String, quantity: Int, status: AdaptiveStatementProfileStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.facility = facility
            self.quantity = quantity
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

        func canMoveTo(_ next: AdaptiveStatementProfileStatus) -> Bool {
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
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveStatementProfileStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveStatementProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive statement profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive statement profile") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(quantity) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveStatementProfile {
            return AdaptiveStatementProfile(
                code: code,
                label: label,
                windowDays: windowDays,
                facility: facility,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive statement profile in status proposed.
    static func newAdaptiveStatementProfile(_ code: String, label: String) -> AdaptiveStatementProfile {
        return AdaptiveStatementProfile(
            code: code,
            label: label,
            windowDays: 0,
            facility: "",
            quantity: 0,
            status: AdaptiveStatementProfileStatus.proposed
        )
    }
}
