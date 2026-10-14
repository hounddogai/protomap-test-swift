import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback interaction bundle is in its life cycle.
    enum FallbackInteractionBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback interaction bundle. Its code is unique within a tenant.
    final class FallbackInteractionBundle {
        var code: String
        var title: String
        var durationMinutes: Int
        var acuity: Int
        var allergy: String
        var floorValue: Double
        var expiresAt: Int
        var tags: [String]
        var windowDays: Int
        var weight: Double
        var minimum: Double
        var status: FallbackInteractionBundleStatus

        init(code: String, title: String, durationMinutes: Int, acuity: Int, allergy: String, floorValue: Double, expiresAt: Int, tags: [String], windowDays: Int, weight: Double, minimum: Double, status: FallbackInteractionBundleStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.acuity = acuity
            self.allergy = allergy
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.tags = tags
            self.windowDays = windowDays
            self.weight = weight
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackInteractionBundleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == FallbackInteractionBundleStatus.published || next == FallbackInteractionBundleStatus.retired
            case .published:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackInteractionBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback interaction bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback interaction bundle") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return ((floorValue + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackInteractionBundle {
            return FallbackInteractionBundle(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                acuity: acuity,
                allergy: allergy,
                floorValue: floorValue,
                expiresAt: expiresAt,
                tags: tags,
                windowDays: windowDays,
                weight: weight,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback interaction bundle in status created.
    static func newFallbackInteractionBundle(_ code: String, title: String) -> FallbackInteractionBundle {
        return FallbackInteractionBundle(
            code: code,
            title: title,
            durationMinutes: 0,
            acuity: 0,
            allergy: "",
            floorValue: 0.0,
            expiresAt: 0,
            tags: [],
            windowDays: 0,
            weight: 0.0,
            minimum: 0.0,
            status: FallbackInteractionBundleStatus.created
        )
    }
}
