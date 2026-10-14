import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive credential mapping is in its life cycle.
    enum AdaptiveCredentialMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One adaptive credential mapping, with what the planners need to act on it.
    final class AdaptiveCredentialMapping {
        var code: String
        var label: String
        var country: String
        var endsAt: Int
        var payer: String
        var approved: Bool
        var limit: Int
        var capacity: Int
        var visible: Bool
        var facility: String
        var status: AdaptiveCredentialMappingStatus

        init(code: String, label: String, country: String, endsAt: Int, payer: String, approved: Bool, limit: Int, capacity: Int, visible: Bool, facility: String, status: AdaptiveCredentialMappingStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.endsAt = endsAt
            self.payer = payer
            self.approved = approved
            self.limit = limit
            self.capacity = capacity
            self.visible = visible
            self.facility = facility
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

        func canMoveTo(_ next: AdaptiveCredentialMappingStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AdaptiveCredentialMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive credential mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive credential mapping") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(capacity) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCredentialMapping {
            return AdaptiveCredentialMapping(
                code: code,
                label: label,
                country: country,
                endsAt: endsAt,
                payer: payer,
                approved: approved,
                limit: limit,
                capacity: capacity,
                visible: visible,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive credential mapping in status proposed.
    static func newAdaptiveCredentialMapping(_ code: String, label: String) -> AdaptiveCredentialMapping {
        return AdaptiveCredentialMapping(
            code: code,
            label: label,
            country: "",
            endsAt: 0,
            payer: "",
            approved: false,
            limit: 0,
            capacity: 0,
            visible: false,
            facility: "",
            status: AdaptiveCredentialMappingStatus.proposed
        )
    }
}
