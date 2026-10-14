import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive cleaning profile is in its life cycle.
    enum AdaptiveCleaningProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive cleaning profile. Its code is unique within a tenant.
    final class AdaptiveCleaningProfile {
        var code: String
        var label: String
        var payer: String
        var currency: String
        var name: String
        var quantity: Int
        var status: AdaptiveCleaningProfileStatus

        init(code: String, label: String, payer: String, currency: String, name: String, quantity: Int, status: AdaptiveCleaningProfileStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.currency = currency
            self.name = name
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveCleaningProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AdaptiveCleaningProfileStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: AdaptiveCleaningProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive cleaning profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> AdaptiveCleaningProfile {
            return AdaptiveCleaningProfile(
                code: code,
                label: label,
                payer: payer,
                currency: currency,
                name: name,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive cleaning profile in status draft.
    static func newAdaptiveCleaningProfile(_ code: String, label: String) -> AdaptiveCleaningProfile {
        return AdaptiveCleaningProfile(
            code: code,
            label: label,
            payer: "",
            currency: "",
            name: "",
            quantity: 0,
            status: AdaptiveCleaningProfileStatus.draft
        )
    }
}
