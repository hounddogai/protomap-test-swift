import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive accession proposal is in its life cycle.
    enum AdaptiveAccessionProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One adaptive accession proposal, with what the planners need to act on it.
    final class AdaptiveAccessionProposal {
        var code: String
        var label: String
        var bed: String
        var facility: String
        var limit: Int
        var name: String
        var version: Int
        var threshold: Double
        var currency: String
        var amount: Double
        var source: String
        var status: AdaptiveAccessionProposalStatus

        init(code: String, label: String, bed: String, facility: String, limit: Int, name: String, version: Int, threshold: Double, currency: String, amount: Double, source: String, status: AdaptiveAccessionProposalStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.facility = facility
            self.limit = limit
            self.name = name
            self.version = version
            self.threshold = threshold
            self.currency = currency
            self.amount = amount
            self.source = source
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

        func canMoveTo(_ next: AdaptiveAccessionProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveAccessionProposalStatus.resolved || next == AdaptiveAccessionProposalStatus.archived
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

        func moveTo(_ next: AdaptiveAccessionProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive accession proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("adaptive accession proposal") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(limit) + amount) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAccessionProposal {
            return AdaptiveAccessionProposal(
                code: code,
                label: label,
                bed: bed,
                facility: facility,
                limit: limit,
                name: name,
                version: version,
                threshold: threshold,
                currency: currency,
                amount: amount,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive accession proposal in status open.
    static func newAdaptiveAccessionProposal(_ code: String, label: String) -> AdaptiveAccessionProposal {
        return AdaptiveAccessionProposal(
            code: code,
            label: label,
            bed: "",
            facility: "",
            limit: 0,
            name: "",
            version: 0,
            threshold: 0.0,
            currency: "",
            amount: 0.0,
            source: "",
            status: AdaptiveAccessionProposalStatus.`open`
        )
    }
}
