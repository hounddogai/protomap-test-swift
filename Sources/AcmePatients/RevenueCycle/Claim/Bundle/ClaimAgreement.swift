import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim agreement is in its life cycle.
    enum ClaimAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a claim agreement and its current status.
    final class ClaimAgreement {
        var code: String
        var name: String
        var expiresAt: Int
        var encounterID: String
        var batchSize: Int
        var status: ClaimAgreementStatus

        init(code: String, name: String, expiresAt: Int, encounterID: String, batchSize: Int, status: ClaimAgreementStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.encounterID = encounterID
            self.batchSize = batchSize
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

        func canMoveTo(_ next: ClaimAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ClaimAgreementStatus.resolved
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ClaimAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveValue() -> Double {
            return ((Double(expiresAt) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimAgreement {
            return ClaimAgreement(
                code: code,
                name: name,
                expiresAt: expiresAt,
                encounterID: encounterID,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim agreement in status open.
    static func newClaimAgreement(_ code: String, name: String) -> ClaimAgreement {
        return ClaimAgreement(
            code: code,
            name: name,
            expiresAt: 0,
            encounterID: "",
            batchSize: 0,
            status: ClaimAgreementStatus.`open`
        )
    }
}
