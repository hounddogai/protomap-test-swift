import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional inventory policy is in its life cycle.
    enum RegionalInventoryPolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a regional inventory policy and its current status.
    final class RegionalInventoryPolicy {
        var code: String
        var title: String
        var threshold: Double
        var procedureCode: String
        var endsAt: Int
        var attributes: [String: String]
        var status: RegionalInventoryPolicyStatus

        init(code: String, title: String, threshold: Double, procedureCode: String, endsAt: Int, attributes: [String: String], status: RegionalInventoryPolicyStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.procedureCode = procedureCode
            self.endsAt = endsAt
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalInventoryPolicyStatus) -> Bool {
            switch status {
            case .idle:
                return next == RegionalInventoryPolicyStatus.ready
            case .warming:
                return next == RegionalInventoryPolicyStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RegionalInventoryPolicyStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalInventoryPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional inventory policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional inventory policy") \(code)"
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
            return ((threshold + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalInventoryPolicy {
            return RegionalInventoryPolicy(
                code: code,
                title: title,
                threshold: threshold,
                procedureCode: procedureCode,
                endsAt: endsAt,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional inventory policy in status idle.
    static func newRegionalInventoryPolicy(_ code: String, title: String) -> RegionalInventoryPolicy {
        return RegionalInventoryPolicy(
            code: code,
            title: title,
            threshold: 0.0,
            procedureCode: "",
            endsAt: 0,
            attributes: [:],
            status: RegionalInventoryPolicyStatus.idle
        )
    }
}
