import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive network draft is in its life cycle.
    enum AdaptiveNetworkDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive network draft as the network team keeps it.
    final class AdaptiveNetworkDraft {
        var code: String
        var name: String
        var category: String
        var title: String
        var visible: Bool
        var currency: String
        var capacity: Int
        var ward: String
        var expiresAt: Int
        var status: AdaptiveNetworkDraftStatus

        init(code: String, name: String, category: String, title: String, visible: Bool, currency: String, capacity: Int, ward: String, expiresAt: Int, status: AdaptiveNetworkDraftStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.title = title
            self.visible = visible
            self.currency = currency
            self.capacity = capacity
            self.ward = ward
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: AdaptiveNetworkDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AdaptiveNetworkDraftStatus.published || next == AdaptiveNetworkDraftStatus.retired
            case .published:
                return next == AdaptiveNetworkDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveNetworkDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive network draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedValue() -> Double {
            return ((Double(expiresAt) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveNetworkDraft {
            return AdaptiveNetworkDraft(
                code: code,
                name: name,
                category: category,
                title: title,
                visible: visible,
                currency: currency,
                capacity: capacity,
                ward: ward,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive network draft in status created.
    static func newAdaptiveNetworkDraft(_ code: String, name: String) -> AdaptiveNetworkDraft {
        return AdaptiveNetworkDraft(
            code: code,
            name: name,
            category: "",
            title: "",
            visible: false,
            currency: "",
            capacity: 0,
            ward: "",
            expiresAt: 0,
            status: AdaptiveNetworkDraftStatus.created
        )
    }
}
