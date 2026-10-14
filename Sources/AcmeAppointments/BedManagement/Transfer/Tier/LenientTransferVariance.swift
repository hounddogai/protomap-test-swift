import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient transfer variance is in its life cycle.
    enum LenientTransferVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient transfer variance as the transfer team keeps it.
    final class LenientTransferVariance {
        var code: String
        var title: String
        var maximum: Double
        var priority: Int
        var endsAt: Int
        var specialty: String
        var status: LenientTransferVarianceStatus

        init(code: String, title: String, maximum: Double, priority: Int, endsAt: Int, specialty: String, status: LenientTransferVarianceStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.priority = priority
            self.endsAt = endsAt
            self.specialty = specialty
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

        func canMoveTo(_ next: LenientTransferVarianceStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientTransferVarianceStatus.revoked
            case .granted:
                return next == LenientTransferVarianceStatus.expired
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

        func moveTo(_ next: LenientTransferVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient transfer variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient transfer variance") \(code)"
        }

        func weightedVolume() -> Double {
            return ((maximum - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientTransferVariance {
            return LenientTransferVariance(
                code: code,
                title: title,
                maximum: maximum,
                priority: priority,
                endsAt: endsAt,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient transfer variance in status requested.
    static func newLenientTransferVariance(_ code: String, title: String) -> LenientTransferVariance {
        return LenientTransferVariance(
            code: code,
            title: title,
            maximum: 0.0,
            priority: 0,
            endsAt: 0,
            specialty: "",
            status: LenientTransferVarianceStatus.requested
        )
    }
}
