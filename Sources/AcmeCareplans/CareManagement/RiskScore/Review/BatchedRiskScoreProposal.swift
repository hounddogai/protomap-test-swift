import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched risk score proposal is in its life cycle.
    enum BatchedRiskScoreProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a batched risk score proposal and its current status.
    final class BatchedRiskScoreProposal {
        var code: String
        var name: String
        var attributes: [String: String]
        var weight: Double
        var bed: String
        var status: BatchedRiskScoreProposalStatus

        init(code: String, name: String, attributes: [String: String], weight: Double, bed: String, status: BatchedRiskScoreProposalStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.weight = weight
            self.bed = bed
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

        func canMoveTo(_ next: BatchedRiskScoreProposalStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedRiskScoreProposalStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == BatchedRiskScoreProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedRiskScoreProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched risk score proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> BatchedRiskScoreProposal {
            return BatchedRiskScoreProposal(
                code: code,
                name: name,
                attributes: attributes,
                weight: weight,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched risk score proposal in status proposed.
    static func newBatchedRiskScoreProposal(_ code: String, name: String) -> BatchedRiskScoreProposal {
        return BatchedRiskScoreProposal(
            code: code,
            name: name,
            attributes: [:],
            weight: 0.0,
            bed: "",
            status: BatchedRiskScoreProposalStatus.proposed
        )
    }
}
