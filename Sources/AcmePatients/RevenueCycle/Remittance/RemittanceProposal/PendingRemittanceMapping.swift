import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending remittance mapping is in its life cycle.
    enum PendingRemittanceMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A pending remittance mapping. Its code is unique within a tenant.
    final class PendingRemittanceMapping {
        var code: String
        var title: String
        var retries: Int
        var score: Double
        var procedureCode: String
        var graceDays: Int
        var startsAt: Int
        var status: PendingRemittanceMappingStatus

        init(code: String, title: String, retries: Int, score: Double, procedureCode: String, graceDays: Int, startsAt: Int, status: PendingRemittanceMappingStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.score = score
            self.procedureCode = procedureCode
            self.graceDays = graceDays
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingRemittanceMappingStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingRemittanceMappingStatus.withdrawn
            case .approved:
                return next == PendingRemittanceMappingStatus.rejected || next == PendingRemittanceMappingStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PendingRemittanceMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending remittance mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return (Double(retries) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> PendingRemittanceMapping {
            return PendingRemittanceMapping(
                code: code,
                title: title,
                retries: retries,
                score: score,
                procedureCode: procedureCode,
                graceDays: graceDays,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending remittance mapping in status proposed.
    static func newPendingRemittanceMapping(_ code: String, title: String) -> PendingRemittanceMapping {
        return PendingRemittanceMapping(
            code: code,
            title: title,
            retries: 0,
            score: 0.0,
            procedureCode: "",
            graceDays: 0,
            startsAt: 0,
            status: PendingRemittanceMappingStatus.proposed
        )
    }
}
