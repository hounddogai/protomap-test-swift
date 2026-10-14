import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback claim digest is in its life cycle.
    enum FallbackClaimDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback claim digest. Its code is unique within a tenant.
    final class FallbackClaimDigest {
        var code: String
        var label: String
        var maximum: Double
        var expiresAt: Int
        var source: String
        var description: String
        var specialty: String
        var retries: Int
        var refills: Int
        var status: FallbackClaimDigestStatus

        init(code: String, label: String, maximum: Double, expiresAt: Int, source: String, description: String, specialty: String, retries: Int, refills: Int, status: FallbackClaimDigestStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.source = source
            self.description = description
            self.specialty = specialty
            self.retries = retries
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackClaimDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == FallbackClaimDigestStatus.running || next == FallbackClaimDigestStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: FallbackClaimDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback claim digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("fallback claim digest") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(expiresAt) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackClaimDigest {
            return FallbackClaimDigest(
                code: code,
                label: label,
                maximum: maximum,
                expiresAt: expiresAt,
                source: source,
                description: description,
                specialty: specialty,
                retries: retries,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a fallback claim digest in status new.
    static func newFallbackClaimDigest(_ code: String, label: String) -> FallbackClaimDigest {
        return FallbackClaimDigest(
            code: code,
            label: label,
            maximum: 0.0,
            expiresAt: 0,
            source: "",
            description: "",
            specialty: "",
            retries: 0,
            refills: 0,
            status: FallbackClaimDigestStatus.new
        )
    }
}
