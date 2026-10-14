import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance estimate is in its life cycle.
    enum RemittanceEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One remittance estimate, with what the planners need to act on it.
    final class RemittanceEstimate {
        var code: String
        var name: String
        var archived: Bool
        var expiresAt: Int
        var margin: Double
        var durationMinutes: Int
        var procedureCode: String
        var revision: Int
        var batchSize: Int
        var version: Int
        var payer: String
        var status: RemittanceEstimateStatus

        init(code: String, name: String, archived: Bool, expiresAt: Int, margin: Double, durationMinutes: Int, procedureCode: String, revision: Int, batchSize: Int, version: Int, payer: String, status: RemittanceEstimateStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.expiresAt = expiresAt
            self.margin = margin
            self.durationMinutes = durationMinutes
            self.procedureCode = procedureCode
            self.revision = revision
            self.batchSize = batchSize
            self.version = version
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RemittanceEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RemittanceEstimateStatus.archived
            case .resolved:
                return next == RemittanceEstimateStatus.reopened || next == RemittanceEstimateStatus.archived
            case .reopened:
                return next == RemittanceEstimateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return (Double(durationMinutes) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceEstimate {
            return RemittanceEstimate(
                code: code,
                name: name,
                archived: archived,
                expiresAt: expiresAt,
                margin: margin,
                durationMinutes: durationMinutes,
                procedureCode: procedureCode,
                revision: revision,
                batchSize: batchSize,
                version: version,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance estimate in status open.
    static func newRemittanceEstimate(_ code: String, name: String) -> RemittanceEstimate {
        return RemittanceEstimate(
            code: code,
            name: name,
            archived: false,
            expiresAt: 0,
            margin: 0.0,
            durationMinutes: 0,
            procedureCode: "",
            revision: 0,
            batchSize: 0,
            version: 0,
            payer: "",
            status: RemittanceEstimateStatus.`open`
        )
    }
}
