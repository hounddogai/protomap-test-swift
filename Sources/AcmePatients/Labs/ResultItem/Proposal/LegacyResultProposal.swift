import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy result proposal is in its life cycle.
    enum LegacyResultProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy result proposal. Its code is unique within a tenant.
    final class LegacyResultProposal {
        var code: String
        var title: String
        var copay: Double
        var pinned: Bool
        var weight: Double
        var expiresAt: Int
        var encounterID: String
        var label: String
        var patientRef: String
        var batchSize: Int
        var attributes: [String: String]
        var status: LegacyResultProposalStatus

        init(code: String, title: String, copay: Double, pinned: Bool, weight: Double, expiresAt: Int, encounterID: String, label: String, patientRef: String, batchSize: Int, attributes: [String: String], status: LegacyResultProposalStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.pinned = pinned
            self.weight = weight
            self.expiresAt = expiresAt
            self.encounterID = encounterID
            self.label = label
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.attributes = attributes
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

        func canMoveTo(_ next: LegacyResultProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyResultProposalStatus.reopened || next == LegacyResultProposalStatus.archived
            case .inReview:
                return next == LegacyResultProposalStatus.resolved
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LegacyResultProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyResultProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy result proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netVolume() -> Double {
            return ((weight + copay) * 100).rounded() / 100
        }

        func copyValue() -> LegacyResultProposal {
            return LegacyResultProposal(
                code: code,
                title: title,
                copay: copay,
                pinned: pinned,
                weight: weight,
                expiresAt: expiresAt,
                encounterID: encounterID,
                label: label,
                patientRef: patientRef,
                batchSize: batchSize,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy result proposal in status open.
    static func newLegacyResultProposal(_ code: String, title: String) -> LegacyResultProposal {
        return LegacyResultProposal(
            code: code,
            title: title,
            copay: 0.0,
            pinned: false,
            weight: 0.0,
            expiresAt: 0,
            encounterID: "",
            label: "",
            patientRef: "",
            batchSize: 0,
            attributes: [:],
            status: LegacyResultProposalStatus.`open`
        )
    }
}
