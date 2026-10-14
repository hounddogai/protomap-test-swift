import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback result claim is in its life cycle.
    enum FallbackResultClaimStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a fallback result claim and its current status.
    final class FallbackResultClaim {
        var code: String
        var name: String
        var revision: Int
        var country: String
        var createdAt: Int
        var specialty: String
        var status: FallbackResultClaimStatus

        init(code: String, name: String, revision: Int, country: String, createdAt: Int, specialty: String, status: FallbackResultClaimStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.country = country
            self.createdAt = createdAt
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

        func canMoveTo(_ next: FallbackResultClaimStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackResultClaimStatus.revoked || next == FallbackResultClaimStatus.expired
            case .granted:
                return next == FallbackResultClaimStatus.revoked
            case .revoked:
                return next == FallbackResultClaimStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackResultClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback result claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netValue() -> Double {
            return (Double(createdAt) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> FallbackResultClaim {
            return FallbackResultClaim(
                code: code,
                name: name,
                revision: revision,
                country: country,
                createdAt: createdAt,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback result claim in status requested.
    static func newFallbackResultClaim(_ code: String, name: String) -> FallbackResultClaim {
        return FallbackResultClaim(
            code: code,
            name: name,
            revision: 0,
            country: "",
            createdAt: 0,
            specialty: "",
            status: FallbackResultClaimStatus.requested
        )
    }
}
