import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network policy is in its life cycle.
    enum ManualNetworkPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual network policy as the network team keeps it.
    final class ManualNetworkPolicy {
        var code: String
        var name: String
        var sequence: Int
        var reviewer: String
        var tags: [String]
        var attributes: [String: String]
        var endsAt: Int
        var dosageMg: Double
        var ward: String
        var weight: Double
        var title: String
        var status: ManualNetworkPolicyStatus

        init(code: String, name: String, sequence: Int, reviewer: String, tags: [String], attributes: [String: String], endsAt: Int, dosageMg: Double, ward: String, weight: Double, title: String, status: ManualNetworkPolicyStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.reviewer = reviewer
            self.tags = tags
            self.attributes = attributes
            self.endsAt = endsAt
            self.dosageMg = dosageMg
            self.ward = ward
            self.weight = weight
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualNetworkPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ManualNetworkPolicyStatus.inReview || next == ManualNetworkPolicyStatus.resolved
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ManualNetworkPolicyStatus.reopened
            case .reopened:
                return next == ManualNetworkPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualNetworkPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual network policy") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((weight - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ManualNetworkPolicy {
            return ManualNetworkPolicy(
                code: code,
                name: name,
                sequence: sequence,
                reviewer: reviewer,
                tags: tags,
                attributes: attributes,
                endsAt: endsAt,
                dosageMg: dosageMg,
                ward: ward,
                weight: weight,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a manual network policy in status open.
    static func newManualNetworkPolicy(_ code: String, name: String) -> ManualNetworkPolicy {
        return ManualNetworkPolicy(
            code: code,
            name: name,
            sequence: 0,
            reviewer: "",
            tags: [],
            attributes: [:],
            endsAt: 0,
            dosageMg: 0.0,
            ward: "",
            weight: 0.0,
            title: "",
            status: ManualNetworkPolicyStatus.`open`
        )
    }
}
