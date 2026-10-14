import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback reference range proposal is in its life cycle.
    enum FallbackReferenceRangeProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback reference range proposal as the reference range team keeps it.
    final class FallbackReferenceRangeProposal {
        var code: String
        var name: String
        var limit: Int
        var diagnosisCode: String
        var active: Bool
        var allergy: String
        var status: FallbackReferenceRangeProposalStatus

        init(code: String, name: String, limit: Int, diagnosisCode: String, active: Bool, allergy: String, status: FallbackReferenceRangeProposalStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.diagnosisCode = diagnosisCode
            self.active = active
            self.allergy = allergy
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

        func canMoveTo(_ next: FallbackReferenceRangeProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FallbackReferenceRangeProposalStatus.reopened
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

        func moveTo(_ next: FallbackReferenceRangeProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback reference range proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback reference range proposal") \(code)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> FallbackReferenceRangeProposal {
            return FallbackReferenceRangeProposal(
                code: code,
                name: name,
                limit: limit,
                diagnosisCode: diagnosisCode,
                active: active,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback reference range proposal in status open.
    static func newFallbackReferenceRangeProposal(_ code: String, name: String) -> FallbackReferenceRangeProposal {
        return FallbackReferenceRangeProposal(
            code: code,
            name: name,
            limit: 0,
            diagnosisCode: "",
            active: false,
            allergy: "",
            status: FallbackReferenceRangeProposalStatus.`open`
        )
    }
}
