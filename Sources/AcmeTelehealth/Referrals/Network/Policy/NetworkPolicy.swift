import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network policy is in its life cycle.
    enum NetworkPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a network policy and its current status.
    final class NetworkPolicy {
        var code: String
        var title: String
        var endsAt: Int
        var windowDays: Int
        var sequence: Int
        var active: Bool
        var facility: String
        var summary: String
        var locale: String
        var allergy: String
        var status: NetworkPolicyStatus

        init(code: String, title: String, endsAt: Int, windowDays: Int, sequence: Int, active: Bool, facility: String, summary: String, locale: String, allergy: String, status: NetworkPolicyStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.windowDays = windowDays
            self.sequence = sequence
            self.active = active
            self.facility = facility
            self.summary = summary
            self.locale = locale
            self.allergy = allergy
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

        func canMoveTo(_ next: NetworkPolicyStatus) -> Bool {
            switch status {
            case .created:
                return next == NetworkPolicyStatus.validated || next == NetworkPolicyStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == NetworkPolicyStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netExposure() -> Double {
            return (Double(windowDays) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> NetworkPolicy {
            return NetworkPolicy(
                code: code,
                title: title,
                endsAt: endsAt,
                windowDays: windowDays,
                sequence: sequence,
                active: active,
                facility: facility,
                summary: summary,
                locale: locale,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a network policy in status created.
    static func newNetworkPolicy(_ code: String, title: String) -> NetworkPolicy {
        return NetworkPolicy(
            code: code,
            title: title,
            endsAt: 0,
            windowDays: 0,
            sequence: 0,
            active: false,
            facility: "",
            summary: "",
            locale: "",
            allergy: "",
            status: NetworkPolicyStatus.created
        )
    }
}
