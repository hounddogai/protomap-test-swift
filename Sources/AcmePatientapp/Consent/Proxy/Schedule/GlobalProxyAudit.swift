import AcmePlatform
import Foundation

extension Consent {
    /// Where a global proxy audit is in its life cycle.
    enum GlobalProxyAuditStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global proxy audit. Its code is unique within a tenant.
    final class GlobalProxyAudit {
        var code: String
        var title: String
        var ownerID: String
        var approved: Bool
        var checksum: String
        var payer: String
        var sequence: Int
        var encounterID: String
        var ratio: Double
        var region: String
        var status: GlobalProxyAuditStatus

        init(code: String, title: String, ownerID: String, approved: Bool, checksum: String, payer: String, sequence: Int, encounterID: String, ratio: Double, region: String, status: GlobalProxyAuditStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.approved = approved
            self.checksum = checksum
            self.payer = payer
            self.sequence = sequence
            self.encounterID = encounterID
            self.ratio = ratio
            self.region = region
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

        func canMoveTo(_ next: GlobalProxyAuditStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalProxyAuditStatus.resolved
            case .inReview:
                return next == GlobalProxyAuditStatus.resolved || next == GlobalProxyAuditStatus.reopened
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

        func moveTo(_ next: GlobalProxyAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global proxy audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global proxy audit") \(code)"
        }

        func adjustedValue() -> Double {
            return ((ratio - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalProxyAudit {
            return GlobalProxyAudit(
                code: code,
                title: title,
                ownerID: ownerID,
                approved: approved,
                checksum: checksum,
                payer: payer,
                sequence: sequence,
                encounterID: encounterID,
                ratio: ratio,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global proxy audit in status open.
    static func newGlobalProxyAudit(_ code: String, title: String) -> GlobalProxyAudit {
        return GlobalProxyAudit(
            code: code,
            title: title,
            ownerID: "",
            approved: false,
            checksum: "",
            payer: "",
            sequence: 0,
            encounterID: "",
            ratio: 0.0,
            region: "",
            status: GlobalProxyAuditStatus.`open`
        )
    }
}
