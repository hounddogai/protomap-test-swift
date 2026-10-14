import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback disclosure profile is in its life cycle.
    enum FallbackDisclosureProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback disclosure profile as the disclosure team keeps it.
    final class FallbackDisclosureProfile {
        var code: String
        var title: String
        var visitMinutes: Int
        var discount: Double
        var graceDays: Int
        var batchSize: Int
        var attempts: Int
        var revision: Int
        var status: FallbackDisclosureProfileStatus

        init(code: String, title: String, visitMinutes: Int, discount: Double, graceDays: Int, batchSize: Int, attempts: Int, revision: Int, status: FallbackDisclosureProfileStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.discount = discount
            self.graceDays = graceDays
            self.batchSize = batchSize
            self.attempts = attempts
            self.revision = revision
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

        func canMoveTo(_ next: FallbackDisclosureProfileStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == FallbackDisclosureProfileStatus.ready || next == FallbackDisclosureProfileStatus.draining
            case .ready:
                return next == FallbackDisclosureProfileStatus.draining || next == FallbackDisclosureProfileStatus.stopped
            case .draining:
                return next == FallbackDisclosureProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackDisclosureProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback disclosure profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return (Double(visitMinutes) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> FallbackDisclosureProfile {
            return FallbackDisclosureProfile(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                discount: discount,
                graceDays: graceDays,
                batchSize: batchSize,
                attempts: attempts,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback disclosure profile in status idle.
    static func newFallbackDisclosureProfile(_ code: String, title: String) -> FallbackDisclosureProfile {
        return FallbackDisclosureProfile(
            code: code,
            title: title,
            visitMinutes: 0,
            discount: 0.0,
            graceDays: 0,
            batchSize: 0,
            attempts: 0,
            revision: 0,
            status: FallbackDisclosureProfileStatus.idle
        )
    }
}
