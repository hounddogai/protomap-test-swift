import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted assessment proposal is in its life cycle.
    enum WeightedAssessmentProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted assessment proposal as the assessment team keeps it.
    final class WeightedAssessmentProposal {
        var code: String
        var label: String
        var weight: Double
        var windowDays: Int
        var encounterID: String
        var status: WeightedAssessmentProposalStatus

        init(code: String, label: String, weight: Double, windowDays: Int, encounterID: String, status: WeightedAssessmentProposalStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.windowDays = windowDays
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedAssessmentProposalStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == WeightedAssessmentProposalStatus.published || next == WeightedAssessmentProposalStatus.retired
            case .published:
                return next == WeightedAssessmentProposalStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedAssessmentProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted assessment proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return ((weight + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedAssessmentProposal {
            return WeightedAssessmentProposal(
                code: code,
                label: label,
                weight: weight,
                windowDays: windowDays,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted assessment proposal in status created.
    static func newWeightedAssessmentProposal(_ code: String, label: String) -> WeightedAssessmentProposal {
        return WeightedAssessmentProposal(
            code: code,
            label: label,
            weight: 0.0,
            windowDays: 0,
            encounterID: "",
            status: WeightedAssessmentProposalStatus.created
        )
    }
}
