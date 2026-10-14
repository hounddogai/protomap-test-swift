import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance rollup is in its life cycle.
    enum RemittanceRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One remittance rollup, with what the planners need to act on it.
    final class RemittanceRollup {
        var code: String
        var name: String
        var expiresAt: Int
        var refills: Int
        var timezone: String
        var capacity: Int
        var priority: Int
        var diagnosisCode: String
        var acuity: Int
        var encounterID: String
        var status: RemittanceRollupStatus

        init(code: String, name: String, expiresAt: Int, refills: Int, timezone: String, capacity: Int, priority: Int, diagnosisCode: String, acuity: Int, encounterID: String, status: RemittanceRollupStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.refills = refills
            self.timezone = timezone
            self.capacity = capacity
            self.priority = priority
            self.diagnosisCode = diagnosisCode
            self.acuity = acuity
            self.encounterID = encounterID
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

        func canMoveTo(_ next: RemittanceRollupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RemittanceRollupStatus.revoked
            case .revoked:
                return next == RemittanceRollupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedValue() -> Double {
            return (Double(priority) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceRollup {
            return RemittanceRollup(
                code: code,
                name: name,
                expiresAt: expiresAt,
                refills: refills,
                timezone: timezone,
                capacity: capacity,
                priority: priority,
                diagnosisCode: diagnosisCode,
                acuity: acuity,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance rollup in status requested.
    static func newRemittanceRollup(_ code: String, name: String) -> RemittanceRollup {
        return RemittanceRollup(
            code: code,
            name: name,
            expiresAt: 0,
            refills: 0,
            timezone: "",
            capacity: 0,
            priority: 0,
            diagnosisCode: "",
            acuity: 0,
            encounterID: "",
            status: RemittanceRollupStatus.requested
        )
    }
}
