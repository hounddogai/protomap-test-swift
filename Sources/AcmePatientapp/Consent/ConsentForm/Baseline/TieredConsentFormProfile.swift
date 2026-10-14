import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered consent form profile is in its life cycle.
    enum TieredConsentFormProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered consent form profile as the consent form team keeps it.
    final class TieredConsentFormProfile {
        var code: String
        var title: String
        var diagnosisCode: String
        var attributes: [String: String]
        var pinned: Bool
        var checksum: String
        var floorValue: Double
        var label: String
        var priority: Int
        var quantity: Int
        var status: TieredConsentFormProfileStatus

        init(code: String, title: String, diagnosisCode: String, attributes: [String: String], pinned: Bool, checksum: String, floorValue: Double, label: String, priority: Int, quantity: Int, status: TieredConsentFormProfileStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.attributes = attributes
            self.pinned = pinned
            self.checksum = checksum
            self.floorValue = floorValue
            self.label = label
            self.priority = priority
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

        func canMoveTo(_ next: TieredConsentFormProfileStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredConsentFormProfileStatus.revoked
            case .granted:
                return next == TieredConsentFormProfileStatus.revoked || next == TieredConsentFormProfileStatus.expired
            case .revoked:
                return next == TieredConsentFormProfileStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredConsentFormProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered consent form profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered consent form profile") \(code)"
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
            return ((floorValue - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> TieredConsentFormProfile {
            return TieredConsentFormProfile(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                attributes: attributes,
                pinned: pinned,
                checksum: checksum,
                floorValue: floorValue,
                label: label,
                priority: priority,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered consent form profile in status requested.
    static func newTieredConsentFormProfile(_ code: String, title: String) -> TieredConsentFormProfile {
        return TieredConsentFormProfile(
            code: code,
            title: title,
            diagnosisCode: "",
            attributes: [:],
            pinned: false,
            checksum: "",
            floorValue: 0.0,
            label: "",
            priority: 0,
            quantity: 0,
            status: TieredConsentFormProfileStatus.requested
        )
    }
}
