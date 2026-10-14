import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive claim snapshot is in its life cycle.
    enum AdaptiveClaimSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive claim snapshot, with what the planners need to act on it.
    final class AdaptiveClaimSnapshot {
        var code: String
        var name: String
        var currency: String
        var expiresAt: Int
        var startsAt: Int
        var visible: Bool
        var attributes: [String: String]
        var status: AdaptiveClaimSnapshotStatus

        init(code: String, name: String, currency: String, expiresAt: Int, startsAt: Int, visible: Bool, attributes: [String: String], status: AdaptiveClaimSnapshotStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.expiresAt = expiresAt
            self.startsAt = startsAt
            self.visible = visible
            self.attributes = attributes
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

        func canMoveTo(_ next: AdaptiveClaimSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AdaptiveClaimSnapshotStatus.expired
            case .revoked:
                return next == AdaptiveClaimSnapshotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveClaimSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive claim snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive claim snapshot") \(code)"
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

        func projectedTotal() -> Double {
            return ((Double(expiresAt) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveClaimSnapshot {
            return AdaptiveClaimSnapshot(
                code: code,
                name: name,
                currency: currency,
                expiresAt: expiresAt,
                startsAt: startsAt,
                visible: visible,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive claim snapshot in status requested.
    static func newAdaptiveClaimSnapshot(_ code: String, name: String) -> AdaptiveClaimSnapshot {
        return AdaptiveClaimSnapshot(
            code: code,
            name: name,
            currency: "",
            expiresAt: 0,
            startsAt: 0,
            visible: false,
            attributes: [:],
            status: AdaptiveClaimSnapshotStatus.requested
        )
    }
}
