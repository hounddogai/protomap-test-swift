import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback credential segment is in its life cycle.
    enum FallbackCredentialSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback credential segment as the credential team keeps it.
    final class FallbackCredentialSegment {
        var code: String
        var title: String
        var clinicianID: String
        var specialty: String
        var graceDays: Int
        var capacity: Int
        var threshold: Double
        var status: FallbackCredentialSegmentStatus

        init(code: String, title: String, clinicianID: String, specialty: String, graceDays: Int, capacity: Int, threshold: Double, status: FallbackCredentialSegmentStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.graceDays = graceDays
            self.capacity = capacity
            self.threshold = threshold
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

        func canMoveTo(_ next: FallbackCredentialSegmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackCredentialSegmentStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackCredentialSegmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCredentialSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback credential segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return ((Double(capacity) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCredentialSegment {
            return FallbackCredentialSegment(
                code: code,
                title: title,
                clinicianID: clinicianID,
                specialty: specialty,
                graceDays: graceDays,
                capacity: capacity,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback credential segment in status requested.
    static func newFallbackCredentialSegment(_ code: String, title: String) -> FallbackCredentialSegment {
        return FallbackCredentialSegment(
            code: code,
            title: title,
            clinicianID: "",
            specialty: "",
            graceDays: 0,
            capacity: 0,
            threshold: 0.0,
            status: FallbackCredentialSegmentStatus.requested
        )
    }
}
