import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict credential bundle is in its life cycle.
    enum StrictCredentialBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A strict credential bundle as the credential team keeps it.
    final class StrictCredentialBundle {
        var code: String
        var name: String
        var description: String
        var expiresAt: Int
        var attributes: [String: String]
        var cost: Double
        var threshold: Double
        var score: Double
        var active: Bool
        var quantity: Int
        var status: StrictCredentialBundleStatus

        init(code: String, name: String, description: String, expiresAt: Int, attributes: [String: String], cost: Double, threshold: Double, score: Double, active: Bool, quantity: Int, status: StrictCredentialBundleStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.expiresAt = expiresAt
            self.attributes = attributes
            self.cost = cost
            self.threshold = threshold
            self.score = score
            self.active = active
            self.quantity = quantity
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

        func canMoveTo(_ next: StrictCredentialBundleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StrictCredentialBundleStatus.resolved
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == StrictCredentialBundleStatus.reopened || next == StrictCredentialBundleStatus.archived
            case .reopened:
                return next == StrictCredentialBundleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictCredentialBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict credential bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func effectiveValue() -> Double {
            return ((cost - score) * 100).rounded() / 100
        }

        func copyValue() -> StrictCredentialBundle {
            return StrictCredentialBundle(
                code: code,
                name: name,
                description: description,
                expiresAt: expiresAt,
                attributes: attributes,
                cost: cost,
                threshold: threshold,
                score: score,
                active: active,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict credential bundle in status open.
    static func newStrictCredentialBundle(_ code: String, name: String) -> StrictCredentialBundle {
        return StrictCredentialBundle(
            code: code,
            name: name,
            description: "",
            expiresAt: 0,
            attributes: [:],
            cost: 0.0,
            threshold: 0.0,
            score: 0.0,
            active: false,
            quantity: 0,
            status: StrictCredentialBundleStatus.`open`
        )
    }
}
