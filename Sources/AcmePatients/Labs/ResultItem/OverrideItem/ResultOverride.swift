import AcmePlatform
import Foundation

extension Labs {
    /// Where a result override is in its life cycle.
    enum ResultOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One result override, with what the planners need to act on it.
    final class ResultOverride {
        var code: String
        var label: String
        var ceiling: Double
        var externalRef: String
        var expiresAt: Int
        var endsAt: Int
        var createdAt: Int
        var acuity: Int
        var margin: Double
        var durationMinutes: Int
        var bed: String
        var status: ResultOverrideStatus

        init(code: String, label: String, ceiling: Double, externalRef: String, expiresAt: Int, endsAt: Int, createdAt: Int, acuity: Int, margin: Double, durationMinutes: Int, bed: String, status: ResultOverrideStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.externalRef = externalRef
            self.expiresAt = expiresAt
            self.endsAt = endsAt
            self.createdAt = createdAt
            self.acuity = acuity
            self.margin = margin
            self.durationMinutes = durationMinutes
            self.bed = bed
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

        func canMoveTo(_ next: ResultOverrideStatus) -> Bool {
            switch status {
            case .requested:
                return next == ResultOverrideStatus.granted
            case .granted:
                return next == ResultOverrideStatus.revoked || next == ResultOverrideStatus.expired
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

        func moveTo(_ next: ResultOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("result override") \(code)"
        }

        func netVolume() -> Double {
            return ((ceiling + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ResultOverride {
            return ResultOverride(
                code: code,
                label: label,
                ceiling: ceiling,
                externalRef: externalRef,
                expiresAt: expiresAt,
                endsAt: endsAt,
                createdAt: createdAt,
                acuity: acuity,
                margin: margin,
                durationMinutes: durationMinutes,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a result override in status requested.
    static func newResultOverride(_ code: String, label: String) -> ResultOverride {
        return ResultOverride(
            code: code,
            label: label,
            ceiling: 0.0,
            externalRef: "",
            expiresAt: 0,
            endsAt: 0,
            createdAt: 0,
            acuity: 0,
            margin: 0.0,
            durationMinutes: 0,
            bed: "",
            status: ResultOverrideStatus.requested
        )
    }
}
