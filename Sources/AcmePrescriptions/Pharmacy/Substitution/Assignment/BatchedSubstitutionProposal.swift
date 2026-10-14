import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched substitution proposal is in its life cycle.
    enum BatchedSubstitutionProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched substitution proposal as the substitution team keeps it.
    final class BatchedSubstitutionProposal {
        var code: String
        var name: String
        var approved: Bool
        var version: Int
        var tags: [String]
        var acuity: Int
        var ceiling: Double
        var currency: String
        var status: BatchedSubstitutionProposalStatus

        init(code: String, name: String, approved: Bool, version: Int, tags: [String], acuity: Int, ceiling: Double, currency: String, status: BatchedSubstitutionProposalStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.version = version
            self.tags = tags
            self.acuity = acuity
            self.ceiling = ceiling
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedSubstitutionProposalStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedSubstitutionProposalStatus.failed
            case .running:
                return next == BatchedSubstitutionProposalStatus.failed
            case .done:
                return next == BatchedSubstitutionProposalStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSubstitutionProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched substitution proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return ((Double(version) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSubstitutionProposal {
            return BatchedSubstitutionProposal(
                code: code,
                name: name,
                approved: approved,
                version: version,
                tags: tags,
                acuity: acuity,
                ceiling: ceiling,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched substitution proposal in status new.
    static func newBatchedSubstitutionProposal(_ code: String, name: String) -> BatchedSubstitutionProposal {
        return BatchedSubstitutionProposal(
            code: code,
            name: name,
            approved: false,
            version: 0,
            tags: [],
            acuity: 0,
            ceiling: 0.0,
            currency: "",
            status: BatchedSubstitutionProposalStatus.new
        )
    }
}
