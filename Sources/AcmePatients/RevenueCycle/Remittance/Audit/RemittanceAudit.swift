import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance audit is in its life cycle.
    enum RemittanceAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a remittance audit and its current status.
    final class RemittanceAudit {
        var code: String
        var label: String
        var ownerID: String
        var revision: Int
        var specialty: String
        var country: String
        var expiresAt: Int
        var tags: [String]
        var title: String
        var ceiling: Double
        var status: RemittanceAuditStatus

        init(code: String, label: String, ownerID: String, revision: Int, specialty: String, country: String, expiresAt: Int, tags: [String], title: String, ceiling: Double, status: RemittanceAuditStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.revision = revision
            self.specialty = specialty
            self.country = country
            self.expiresAt = expiresAt
            self.tags = tags
            self.title = title
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RemittanceAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == RemittanceAuditStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RemittanceAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return (Double(expiresAt) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceAudit {
            return RemittanceAudit(
                code: code,
                label: label,
                ownerID: ownerID,
                revision: revision,
                specialty: specialty,
                country: country,
                expiresAt: expiresAt,
                tags: tags,
                title: title,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a remittance audit in status created.
    static func newRemittanceAudit(_ code: String, label: String) -> RemittanceAudit {
        return RemittanceAudit(
            code: code,
            label: label,
            ownerID: "",
            revision: 0,
            specialty: "",
            country: "",
            expiresAt: 0,
            tags: [],
            title: "",
            ceiling: 0.0,
            status: RemittanceAuditStatus.created
        )
    }
}
