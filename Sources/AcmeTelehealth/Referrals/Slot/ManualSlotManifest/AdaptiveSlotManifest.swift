import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive slot manifest is in its life cycle.
    enum AdaptiveSlotManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive slot manifest, with what the planners need to act on it.
    final class AdaptiveSlotManifest {
        var code: String
        var name: String
        var priority: Int
        var ceiling: Double
        var title: String
        var weight: Double
        var margin: Double
        var status: AdaptiveSlotManifestStatus

        init(code: String, name: String, priority: Int, ceiling: Double, title: String, weight: Double, margin: Double, status: AdaptiveSlotManifestStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.ceiling = ceiling
            self.title = title
            self.weight = weight
            self.margin = margin
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

        func canMoveTo(_ next: AdaptiveSlotManifestStatus) -> Bool {
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
                return next == AdaptiveSlotManifestStatus.expired
            case .revoked:
                return next == AdaptiveSlotManifestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveSlotManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive slot manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive slot manifest") \(code)"
        }

        func adjustedValue() -> Double {
            return ((margin + weight) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveSlotManifest {
            return AdaptiveSlotManifest(
                code: code,
                name: name,
                priority: priority,
                ceiling: ceiling,
                title: title,
                weight: weight,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive slot manifest in status requested.
    static func newAdaptiveSlotManifest(_ code: String, name: String) -> AdaptiveSlotManifest {
        return AdaptiveSlotManifest(
            code: code,
            name: name,
            priority: 0,
            ceiling: 0.0,
            title: "",
            weight: 0.0,
            margin: 0.0,
            status: AdaptiveSlotManifestStatus.requested
        )
    }
}
