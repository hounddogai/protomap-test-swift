import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional claim profile is in its life cycle.
    enum RegionalClaimProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional claim profile, with what the planners need to act on it.
    final class RegionalClaimProfile {
        var code: String
        var title: String
        var procedureCode: String
        var quantity: Int
        var archived: Bool
        var visible: Bool
        var name: String
        var unit: String
        var status: RegionalClaimProfileStatus

        init(code: String, title: String, procedureCode: String, quantity: Int, archived: Bool, visible: Bool, name: String, unit: String, status: RegionalClaimProfileStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.quantity = quantity
            self.archived = archived
            self.visible = visible
            self.name = name
            self.unit = unit
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

        func canMoveTo(_ next: RegionalClaimProfileStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalClaimProfileStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RegionalClaimProfileStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalClaimProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional claim profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional claim profile") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> RegionalClaimProfile {
            return RegionalClaimProfile(
                code: code,
                title: title,
                procedureCode: procedureCode,
                quantity: quantity,
                archived: archived,
                visible: visible,
                name: name,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional claim profile in status proposed.
    static func newRegionalClaimProfile(_ code: String, title: String) -> RegionalClaimProfile {
        return RegionalClaimProfile(
            code: code,
            title: title,
            procedureCode: "",
            quantity: 0,
            archived: false,
            visible: false,
            name: "",
            unit: "",
            status: RegionalClaimProfileStatus.proposed
        )
    }
}
