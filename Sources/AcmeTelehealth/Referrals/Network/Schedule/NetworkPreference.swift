import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network preference is in its life cycle.
    enum NetworkPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One network preference, with what the planners need to act on it.
    final class NetworkPreference {
        var code: String
        var label: String
        var externalRef: String
        var segment: String
        var maximum: Double
        var archived: Bool
        var contactEmail: String
        var startsAt: Int
        var notes: String
        var quantity: Int
        var status: NetworkPreferenceStatus

        init(code: String, label: String, externalRef: String, segment: String, maximum: Double, archived: Bool, contactEmail: String, startsAt: Int, notes: String, quantity: Int, status: NetworkPreferenceStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.segment = segment
            self.maximum = maximum
            self.archived = archived
            self.contactEmail = contactEmail
            self.startsAt = startsAt
            self.notes = notes
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

        func canMoveTo(_ next: NetworkPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                return next == NetworkPreferenceStatus.granted || next == NetworkPreferenceStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == NetworkPreferenceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((maximum - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkPreference {
            return NetworkPreference(
                code: code,
                label: label,
                externalRef: externalRef,
                segment: segment,
                maximum: maximum,
                archived: archived,
                contactEmail: contactEmail,
                startsAt: startsAt,
                notes: notes,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a network preference in status requested.
    static func newNetworkPreference(_ code: String, label: String) -> NetworkPreference {
        return NetworkPreference(
            code: code,
            label: label,
            externalRef: "",
            segment: "",
            maximum: 0.0,
            archived: false,
            contactEmail: "",
            startsAt: 0,
            notes: "",
            quantity: 0,
            status: NetworkPreferenceStatus.requested
        )
    }
}
