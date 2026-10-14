import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global network group is in its life cycle.
    enum GlobalNetworkGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a global network group and its current status.
    final class GlobalNetworkGroup {
        var code: String
        var label: String
        var facility: String
        var sequence: Int
        var revision: Int
        var tags: [String]
        var archived: Bool
        var status: GlobalNetworkGroupStatus

        init(code: String, label: String, facility: String, sequence: Int, revision: Int, tags: [String], archived: Bool, status: GlobalNetworkGroupStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.sequence = sequence
            self.revision = revision
            self.tags = tags
            self.archived = archived
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

        func canMoveTo(_ next: GlobalNetworkGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == GlobalNetworkGroupStatus.reopened
            case .resolved:
                return next == GlobalNetworkGroupStatus.reopened
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

        func moveTo(_ next: GlobalNetworkGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global network group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("global network group") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((Double(sequence) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalNetworkGroup {
            return GlobalNetworkGroup(
                code: code,
                label: label,
                facility: facility,
                sequence: sequence,
                revision: revision,
                tags: tags,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a global network group in status open.
    static func newGlobalNetworkGroup(_ code: String, label: String) -> GlobalNetworkGroup {
        return GlobalNetworkGroup(
            code: code,
            label: label,
            facility: "",
            sequence: 0,
            revision: 0,
            tags: [],
            archived: false,
            status: GlobalNetworkGroupStatus.`open`
        )
    }
}
