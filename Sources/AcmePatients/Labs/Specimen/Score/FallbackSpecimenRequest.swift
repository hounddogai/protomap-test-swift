import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback specimen request is in its life cycle.
    enum FallbackSpecimenRequestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One fallback specimen request, with what the planners need to act on it.
    final class FallbackSpecimenRequest {
        var code: String
        var title: String
        var pinned: Bool
        var attempts: Int
        var tags: [String]
        var locale: String
        var acuity: Int
        var source: String
        var budget: Double
        var maximum: Double
        var status: FallbackSpecimenRequestStatus

        init(code: String, title: String, pinned: Bool, attempts: Int, tags: [String], locale: String, acuity: Int, source: String, budget: Double, maximum: Double, status: FallbackSpecimenRequestStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.attempts = attempts
            self.tags = tags
            self.locale = locale
            self.acuity = acuity
            self.source = source
            self.budget = budget
            self.maximum = maximum
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

        func canMoveTo(_ next: FallbackSpecimenRequestStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackSpecimenRequestStatus.expired
            case .granted:
                return next == FallbackSpecimenRequestStatus.revoked || next == FallbackSpecimenRequestStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: FallbackSpecimenRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback specimen request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback specimen request") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((Double(acuity) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackSpecimenRequest {
            return FallbackSpecimenRequest(
                code: code,
                title: title,
                pinned: pinned,
                attempts: attempts,
                tags: tags,
                locale: locale,
                acuity: acuity,
                source: source,
                budget: budget,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a fallback specimen request in status requested.
    static func newFallbackSpecimenRequest(_ code: String, title: String) -> FallbackSpecimenRequest {
        return FallbackSpecimenRequest(
            code: code,
            title: title,
            pinned: false,
            attempts: 0,
            tags: [],
            locale: "",
            acuity: 0,
            source: "",
            budget: 0.0,
            maximum: 0.0,
            status: FallbackSpecimenRequestStatus.requested
        )
    }
}
