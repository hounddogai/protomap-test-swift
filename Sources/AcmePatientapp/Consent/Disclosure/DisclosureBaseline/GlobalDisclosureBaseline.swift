import AcmePlatform
import Foundation

extension Consent {
    /// Where a global disclosure baseline is in its life cycle.
    enum GlobalDisclosureBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global disclosure baseline, with what the planners need to act on it.
    final class GlobalDisclosureBaseline {
        var code: String
        var name: String
        var clinicianID: String
        var region: String
        var segment: String
        var quantity: Int
        var status: GlobalDisclosureBaselineStatus

        init(code: String, name: String, clinicianID: String, region: String, segment: String, quantity: Int, status: GlobalDisclosureBaselineStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.region = region
            self.segment = segment
            self.quantity = quantity
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

        func canMoveTo(_ next: GlobalDisclosureBaselineStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == GlobalDisclosureBaselineStatus.revoked || next == GlobalDisclosureBaselineStatus.expired
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

        func moveTo(_ next: GlobalDisclosureBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global disclosure baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global disclosure baseline") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> GlobalDisclosureBaseline {
            return GlobalDisclosureBaseline(
                code: code,
                name: name,
                clinicianID: clinicianID,
                region: region,
                segment: segment,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global disclosure baseline in status requested.
    static func newGlobalDisclosureBaseline(_ code: String, name: String) -> GlobalDisclosureBaseline {
        return GlobalDisclosureBaseline(
            code: code,
            name: name,
            clinicianID: "",
            region: "",
            segment: "",
            quantity: 0,
            status: GlobalDisclosureBaselineStatus.requested
        )
    }
}
