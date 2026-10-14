import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered risk score claim is in its life cycle.
    enum TieredRiskScoreClaimStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered risk score claim. Its code is unique within a tenant.
    final class TieredRiskScoreClaim {
        var code: String
        var name: String
        var procedureCode: String
        var externalRef: String
        var minimum: Double
        var ceiling: Double
        var channel: String
        var endsAt: Int
        var category: String
        var status: TieredRiskScoreClaimStatus

        init(code: String, name: String, procedureCode: String, externalRef: String, minimum: Double, ceiling: Double, channel: String, endsAt: Int, category: String, status: TieredRiskScoreClaimStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.externalRef = externalRef
            self.minimum = minimum
            self.ceiling = ceiling
            self.channel = channel
            self.endsAt = endsAt
            self.category = category
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

        func canMoveTo(_ next: TieredRiskScoreClaimStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredRiskScoreClaimStatus.granted || next == TieredRiskScoreClaimStatus.expired
            case .granted:
                return next == TieredRiskScoreClaimStatus.revoked
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

        func moveTo(_ next: TieredRiskScoreClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered risk score claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return (minimum * ceiling * 100).rounded() / 100
        }

        func copyValue() -> TieredRiskScoreClaim {
            return TieredRiskScoreClaim(
                code: code,
                name: name,
                procedureCode: procedureCode,
                externalRef: externalRef,
                minimum: minimum,
                ceiling: ceiling,
                channel: channel,
                endsAt: endsAt,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a tiered risk score claim in status requested.
    static func newTieredRiskScoreClaim(_ code: String, name: String) -> TieredRiskScoreClaim {
        return TieredRiskScoreClaim(
            code: code,
            name: name,
            procedureCode: "",
            externalRef: "",
            minimum: 0.0,
            ceiling: 0.0,
            channel: "",
            endsAt: 0,
            category: "",
            status: TieredRiskScoreClaimStatus.requested
        )
    }
}
