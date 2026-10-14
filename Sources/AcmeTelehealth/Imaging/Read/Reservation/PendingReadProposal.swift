import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending read proposal is in its life cycle.
    enum PendingReadProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending read proposal. Its code is unique within a tenant.
    final class PendingReadProposal {
        var code: String
        var label: String
        var batchSize: Int
        var locale: String
        var checksum: String
        var visible: Bool
        var notes: String
        var category: String
        var status: PendingReadProposalStatus

        init(code: String, label: String, batchSize: Int, locale: String, checksum: String, visible: Bool, notes: String, category: String, status: PendingReadProposalStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.locale = locale
            self.checksum = checksum
            self.visible = visible
            self.notes = notes
            self.category = category
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

        func canMoveTo(_ next: PendingReadProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingReadProposalStatus.inReview || next == PendingReadProposalStatus.reopened
            case .inReview:
                return next == PendingReadProposalStatus.archived
            case .resolved:
                return next == PendingReadProposalStatus.reopened || next == PendingReadProposalStatus.archived
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

        func moveTo(_ next: PendingReadProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending read proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> PendingReadProposal {
            return PendingReadProposal(
                code: code,
                label: label,
                batchSize: batchSize,
                locale: locale,
                checksum: checksum,
                visible: visible,
                notes: notes,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending read proposal in status open.
    static func newPendingReadProposal(_ code: String, label: String) -> PendingReadProposal {
        return PendingReadProposal(
            code: code,
            label: label,
            batchSize: 0,
            locale: "",
            checksum: "",
            visible: false,
            notes: "",
            category: "",
            status: PendingReadProposalStatus.`open`
        )
    }
}
