import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient care protocol policy is in its life cycle.
    enum LenientCareProtocolPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient care protocol policy as the care protocol team keeps it.
    final class LenientCareProtocolPolicy {
        var code: String
        var title: String
        var channel: String
        var name: String
        var capacity: Int
        var threshold: Double
        var floorValue: Double
        var allergy: String
        var expiresAt: Int
        var retries: Int
        var status: LenientCareProtocolPolicyStatus

        init(code: String, title: String, channel: String, name: String, capacity: Int, threshold: Double, floorValue: Double, allergy: String, expiresAt: Int, retries: Int, status: LenientCareProtocolPolicyStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.name = name
            self.capacity = capacity
            self.threshold = threshold
            self.floorValue = floorValue
            self.allergy = allergy
            self.expiresAt = expiresAt
            self.retries = retries
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

        func canMoveTo(_ next: LenientCareProtocolPolicyStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientCareProtocolPolicyStatus.granted
            case .granted:
                return next == LenientCareProtocolPolicyStatus.expired
            case .revoked:
                return next == LenientCareProtocolPolicyStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCareProtocolPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient care protocol policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netValue() -> Double {
            return (Double(capacity) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> LenientCareProtocolPolicy {
            return LenientCareProtocolPolicy(
                code: code,
                title: title,
                channel: channel,
                name: name,
                capacity: capacity,
                threshold: threshold,
                floorValue: floorValue,
                allergy: allergy,
                expiresAt: expiresAt,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a lenient care protocol policy in status requested.
    static func newLenientCareProtocolPolicy(_ code: String, title: String) -> LenientCareProtocolPolicy {
        return LenientCareProtocolPolicy(
            code: code,
            title: title,
            channel: "",
            name: "",
            capacity: 0,
            threshold: 0.0,
            floorValue: 0.0,
            allergy: "",
            expiresAt: 0,
            retries: 0,
            status: LenientCareProtocolPolicyStatus.requested
        )
    }
}
