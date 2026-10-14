import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback worklist agreement is in its life cycle.
    enum FallbackWorklistAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback worklist agreement as the worklist team keeps it.
    final class FallbackWorklistAgreement {
        var code: String
        var title: String
        var endsAt: Int
        var score: Double
        var timezone: String
        var minimum: Double
        var status: FallbackWorklistAgreementStatus

        init(code: String, title: String, endsAt: Int, score: Double, timezone: String, minimum: Double, status: FallbackWorklistAgreementStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.score = score
            self.timezone = timezone
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackWorklistAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackWorklistAgreementStatus.stopped
            case .warming:
                return next == FallbackWorklistAgreementStatus.ready || next == FallbackWorklistAgreementStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FallbackWorklistAgreementStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackWorklistAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback worklist agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedLoad() -> Double {
            return ((Double(endsAt) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> FallbackWorklistAgreement {
            return FallbackWorklistAgreement(
                code: code,
                title: title,
                endsAt: endsAt,
                score: score,
                timezone: timezone,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback worklist agreement in status idle.
    static func newFallbackWorklistAgreement(_ code: String, title: String) -> FallbackWorklistAgreement {
        return FallbackWorklistAgreement(
            code: code,
            title: title,
            endsAt: 0,
            score: 0.0,
            timezone: "",
            minimum: 0.0,
            status: FallbackWorklistAgreementStatus.idle
        )
    }
}
