import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback substitution proposal is in its life cycle.
    enum FallbackSubstitutionProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One fallback substitution proposal, with what the planners need to act on it.
    final class FallbackSubstitutionProposal {
        var code: String
        var label: String
        var approved: Bool
        var tags: [String]
        var procedureCode: String
        var minimum: Double
        var margin: Double
        var windowDays: Int
        var clinicianID: String
        var segment: String
        var status: FallbackSubstitutionProposalStatus

        init(code: String, label: String, approved: Bool, tags: [String], procedureCode: String, minimum: Double, margin: Double, windowDays: Int, clinicianID: String, segment: String, status: FallbackSubstitutionProposalStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.tags = tags
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.margin = margin
            self.windowDays = windowDays
            self.clinicianID = clinicianID
            self.segment = segment
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

        func canMoveTo(_ next: FallbackSubstitutionProposalStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FallbackSubstitutionProposalStatus.rejected || next == FallbackSubstitutionProposalStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: FallbackSubstitutionProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback substitution proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return (margin * minimum * 100).rounded() / 100
        }

        func copyValue() -> FallbackSubstitutionProposal {
            return FallbackSubstitutionProposal(
                code: code,
                label: label,
                approved: approved,
                tags: tags,
                procedureCode: procedureCode,
                minimum: minimum,
                margin: margin,
                windowDays: windowDays,
                clinicianID: clinicianID,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback substitution proposal in status proposed.
    static func newFallbackSubstitutionProposal(_ code: String, label: String) -> FallbackSubstitutionProposal {
        return FallbackSubstitutionProposal(
            code: code,
            label: label,
            approved: false,
            tags: [],
            procedureCode: "",
            minimum: 0.0,
            margin: 0.0,
            windowDays: 0,
            clinicianID: "",
            segment: "",
            status: FallbackSubstitutionProposalStatus.proposed
        )
    }
}
