import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement variance is in its life cycle.
    enum StatementVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One statement variance, with what the planners need to act on it.
    final class StatementVariance {
        var code: String
        var label: String
        var refills: Int
        var timezone: String
        var createdAt: Int
        var updatedAt: Int
        var dosageMg: Double
        var status: StatementVarianceStatus

        init(code: String, label: String, refills: Int, timezone: String, createdAt: Int, updatedAt: Int, dosageMg: Double, status: StatementVarianceStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.timezone = timezone
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: StatementVarianceStatus) -> Bool {
            switch status {
            case .requested:
                return next == StatementVarianceStatus.expired
            case .granted:
                return next == StatementVarianceStatus.revoked || next == StatementVarianceStatus.expired
            case .revoked:
                return next == StatementVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return (Double(updatedAt) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> StatementVariance {
            return StatementVariance(
                code: code,
                label: label,
                refills: refills,
                timezone: timezone,
                createdAt: createdAt,
                updatedAt: updatedAt,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a statement variance in status requested.
    static func newStatementVariance(_ code: String, label: String) -> StatementVariance {
        return StatementVariance(
            code: code,
            label: label,
            refills: 0,
            timezone: "",
            createdAt: 0,
            updatedAt: 0,
            dosageMg: 0.0,
            status: StatementVarianceStatus.requested
        )
    }
}
