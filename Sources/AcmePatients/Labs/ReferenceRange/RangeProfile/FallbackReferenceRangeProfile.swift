import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback reference range profile is in its life cycle.
    enum FallbackReferenceRangeProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One fallback reference range profile, with what the planners need to act on it.
    final class FallbackReferenceRangeProfile {
        var code: String
        var label: String
        var segment: String
        var checksum: String
        var currency: String
        var ward: String
        var copay: Double
        var score: Double
        var margin: Double
        var createdAt: Int
        var status: FallbackReferenceRangeProfileStatus

        init(code: String, label: String, segment: String, checksum: String, currency: String, ward: String, copay: Double, score: Double, margin: Double, createdAt: Int, status: FallbackReferenceRangeProfileStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.checksum = checksum
            self.currency = currency
            self.ward = ward
            self.copay = copay
            self.score = score
            self.margin = margin
            self.createdAt = createdAt
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

        func canMoveTo(_ next: FallbackReferenceRangeProfileStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
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
                return next == FallbackReferenceRangeProfileStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackReferenceRangeProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback reference range profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("fallback reference range profile") \(code)"
        }

        func weightedValue() -> Double {
            return ((margin - copay) * 100).rounded() / 100
        }

        func copyValue() -> FallbackReferenceRangeProfile {
            return FallbackReferenceRangeProfile(
                code: code,
                label: label,
                segment: segment,
                checksum: checksum,
                currency: currency,
                ward: ward,
                copay: copay,
                score: score,
                margin: margin,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback reference range profile in status requested.
    static func newFallbackReferenceRangeProfile(_ code: String, label: String) -> FallbackReferenceRangeProfile {
        return FallbackReferenceRangeProfile(
            code: code,
            label: label,
            segment: "",
            checksum: "",
            currency: "",
            ward: "",
            copay: 0.0,
            score: 0.0,
            margin: 0.0,
            createdAt: 0,
            status: FallbackReferenceRangeProfileStatus.requested
        )
    }
}
