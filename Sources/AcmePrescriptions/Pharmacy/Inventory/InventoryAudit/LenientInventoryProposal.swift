import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient inventory proposal is in its life cycle.
    enum LenientInventoryProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a lenient inventory proposal and its current status.
    final class LenientInventoryProposal {
        var code: String
        var label: String
        var source: String
        var tags: [String]
        var capacity: Int
        var encounterID: String
        var reviewer: String
        var patientRef: String
        var summary: String
        var status: LenientInventoryProposalStatus

        init(code: String, label: String, source: String, tags: [String], capacity: Int, encounterID: String, reviewer: String, patientRef: String, summary: String, status: LenientInventoryProposalStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.tags = tags
            self.capacity = capacity
            self.encounterID = encounterID
            self.reviewer = reviewer
            self.patientRef = patientRef
            self.summary = summary
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

        func canMoveTo(_ next: LenientInventoryProposalStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientInventoryProposalStatus.rejected
            case .approved:
                return next == LenientInventoryProposalStatus.withdrawn
            case .rejected:
                return next == LenientInventoryProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientInventoryProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient inventory proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> LenientInventoryProposal {
            return LenientInventoryProposal(
                code: code,
                label: label,
                source: source,
                tags: tags,
                capacity: capacity,
                encounterID: encounterID,
                reviewer: reviewer,
                patientRef: patientRef,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient inventory proposal in status proposed.
    static func newLenientInventoryProposal(_ code: String, label: String) -> LenientInventoryProposal {
        return LenientInventoryProposal(
            code: code,
            label: label,
            source: "",
            tags: [],
            capacity: 0,
            encounterID: "",
            reviewer: "",
            patientRef: "",
            summary: "",
            status: LenientInventoryProposalStatus.proposed
        )
    }
}
