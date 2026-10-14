import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal panel policy is in its life cycle.
    enum SeasonalPanelPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal panel policy as the panel team keeps it.
    final class SeasonalPanelPolicy {
        var code: String
        var name: String
        var phone: String
        var pinned: Bool
        var country: String
        var priority: Int
        var createdAt: Int
        var status: SeasonalPanelPolicyStatus

        init(code: String, name: String, phone: String, pinned: Bool, country: String, priority: Int, createdAt: Int, status: SeasonalPanelPolicyStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.pinned = pinned
            self.country = country
            self.priority = priority
            self.createdAt = createdAt
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

        func canMoveTo(_ next: SeasonalPanelPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalPanelPolicyStatus.rejected || next == SeasonalPanelPolicyStatus.withdrawn
            case .approved:
                return next == SeasonalPanelPolicyStatus.rejected
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

        func moveTo(_ next: SeasonalPanelPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal panel policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal panel policy") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(priority) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalPanelPolicy {
            return SeasonalPanelPolicy(
                code: code,
                name: name,
                phone: phone,
                pinned: pinned,
                country: country,
                priority: priority,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a seasonal panel policy in status proposed.
    static func newSeasonalPanelPolicy(_ code: String, name: String) -> SeasonalPanelPolicy {
        return SeasonalPanelPolicy(
            code: code,
            name: name,
            phone: "",
            pinned: false,
            country: "",
            priority: 0,
            createdAt: 0,
            status: SeasonalPanelPolicyStatus.proposed
        )
    }
}
