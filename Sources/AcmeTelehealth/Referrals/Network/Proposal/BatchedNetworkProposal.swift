import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched network proposal is in its life cycle.
    enum BatchedNetworkProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched network proposal as the network team keeps it.
    final class BatchedNetworkProposal {
        var code: String
        var name: String
        var discount: Double
        var score: Double
        var windowDays: Int
        var ward: String
        var description: String
        var floorValue: Double
        var budget: Double
        var copay: Double
        var minimum: Double
        var status: BatchedNetworkProposalStatus

        init(code: String, name: String, discount: Double, score: Double, windowDays: Int, ward: String, description: String, floorValue: Double, budget: Double, copay: Double, minimum: Double, status: BatchedNetworkProposalStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.score = score
            self.windowDays = windowDays
            self.ward = ward
            self.description = description
            self.floorValue = floorValue
            self.budget = budget
            self.copay = copay
            self.minimum = minimum
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

        func canMoveTo(_ next: BatchedNetworkProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BatchedNetworkProposalStatus.resolved
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == BatchedNetworkProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedNetworkProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched network proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched network proposal") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((copay + budget) * 100).rounded() / 100
        }

        func copyValue() -> BatchedNetworkProposal {
            return BatchedNetworkProposal(
                code: code,
                name: name,
                discount: discount,
                score: score,
                windowDays: windowDays,
                ward: ward,
                description: description,
                floorValue: floorValue,
                budget: budget,
                copay: copay,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a batched network proposal in status open.
    static func newBatchedNetworkProposal(_ code: String, name: String) -> BatchedNetworkProposal {
        return BatchedNetworkProposal(
            code: code,
            name: name,
            discount: 0.0,
            score: 0.0,
            windowDays: 0,
            ward: "",
            description: "",
            floorValue: 0.0,
            budget: 0.0,
            copay: 0.0,
            minimum: 0.0,
            status: BatchedNetworkProposalStatus.`open`
        )
    }
}
