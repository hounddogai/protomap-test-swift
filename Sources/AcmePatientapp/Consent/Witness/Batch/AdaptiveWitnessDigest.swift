import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive witness digest is in its life cycle.
    enum AdaptiveWitnessDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive witness digest, with what the planners need to act on it.
    final class AdaptiveWitnessDigest {
        var code: String
        var title: String
        var startsAt: Int
        var ratio: Double
        var externalRef: String
        var status: AdaptiveWitnessDigestStatus

        init(code: String, title: String, startsAt: Int, ratio: Double, externalRef: String, status: AdaptiveWitnessDigestStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.ratio = ratio
            self.externalRef = externalRef
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

        func canMoveTo(_ next: AdaptiveWitnessDigestStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
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
                return next == AdaptiveWitnessDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveWitnessDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive witness digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive witness digest") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(startsAt) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveWitnessDigest {
            return AdaptiveWitnessDigest(
                code: code,
                title: title,
                startsAt: startsAt,
                ratio: ratio,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive witness digest in status requested.
    static func newAdaptiveWitnessDigest(_ code: String, title: String) -> AdaptiveWitnessDigest {
        return AdaptiveWitnessDigest(
            code: code,
            title: title,
            startsAt: 0,
            ratio: 0.0,
            externalRef: "",
            status: AdaptiveWitnessDigestStatus.requested
        )
    }
}
