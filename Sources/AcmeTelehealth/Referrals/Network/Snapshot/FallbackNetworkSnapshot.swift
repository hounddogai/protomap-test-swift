import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback network snapshot is in its life cycle.
    enum FallbackNetworkSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback network snapshot. Its code is unique within a tenant.
    final class FallbackNetworkSnapshot {
        var code: String
        var title: String
        var allergy: String
        var discount: Double
        var ownerID: String
        var contactEmail: String
        var active: Bool
        var segment: String
        var summary: String
        var status: FallbackNetworkSnapshotStatus

        init(code: String, title: String, allergy: String, discount: Double, ownerID: String, contactEmail: String, active: Bool, segment: String, summary: String, status: FallbackNetworkSnapshotStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.discount = discount
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.active = active
            self.segment = segment
            self.summary = summary
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

        func canMoveTo(_ next: FallbackNetworkSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackNetworkSnapshotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackNetworkSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback network snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> FallbackNetworkSnapshot {
            return FallbackNetworkSnapshot(
                code: code,
                title: title,
                allergy: allergy,
                discount: discount,
                ownerID: ownerID,
                contactEmail: contactEmail,
                active: active,
                segment: segment,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback network snapshot in status requested.
    static func newFallbackNetworkSnapshot(_ code: String, title: String) -> FallbackNetworkSnapshot {
        return FallbackNetworkSnapshot(
            code: code,
            title: title,
            allergy: "",
            discount: 0.0,
            ownerID: "",
            contactEmail: "",
            active: false,
            segment: "",
            summary: "",
            status: FallbackNetworkSnapshotStatus.requested
        )
    }
}
