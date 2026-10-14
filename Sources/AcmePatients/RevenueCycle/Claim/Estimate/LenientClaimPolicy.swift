import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient claim policy is in its life cycle.
    enum LenientClaimPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a lenient claim policy and its current status.
    final class LenientClaimPolicy {
        var code: String
        var name: String
        var description: String
        var region: String
        var archived: Bool
        var attributes: [String: String]
        var locale: String
        var score: Double
        var status: LenientClaimPolicyStatus

        init(code: String, name: String, description: String, region: String, archived: Bool, attributes: [String: String], locale: String, score: Double, status: LenientClaimPolicyStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.region = region
            self.archived = archived
            self.attributes = attributes
            self.locale = locale
            self.score = score
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

        func canMoveTo(_ next: LenientClaimPolicyStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LenientClaimPolicyStatus.suspended || next == LenientClaimPolicyStatus.closed
            case .suspended:
                return next == LenientClaimPolicyStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientClaimPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient claim policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> LenientClaimPolicy {
            return LenientClaimPolicy(
                code: code,
                name: name,
                description: description,
                region: region,
                archived: archived,
                attributes: attributes,
                locale: locale,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient claim policy in status draft.
    static func newLenientClaimPolicy(_ code: String, name: String) -> LenientClaimPolicy {
        return LenientClaimPolicy(
            code: code,
            name: name,
            description: "",
            region: "",
            archived: false,
            attributes: [:],
            locale: "",
            score: 0.0,
            status: LenientClaimPolicyStatus.draft
        )
    }
}
