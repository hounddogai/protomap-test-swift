import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled witness proposal is in its life cycle.
    enum ScheduledWitnessProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One scheduled witness proposal, with what the planners need to act on it.
    final class ScheduledWitnessProposal {
        var code: String
        var name: String
        var procedureCode: String
        var source: String
        var unit: String
        var margin: Double
        var externalRef: String
        var durationMinutes: Int
        var priority: Int
        var acuity: Int
        var approved: Bool
        var status: ScheduledWitnessProposalStatus

        init(code: String, name: String, procedureCode: String, source: String, unit: String, margin: Double, externalRef: String, durationMinutes: Int, priority: Int, acuity: Int, approved: Bool, status: ScheduledWitnessProposalStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.source = source
            self.unit = unit
            self.margin = margin
            self.externalRef = externalRef
            self.durationMinutes = durationMinutes
            self.priority = priority
            self.acuity = acuity
            self.approved = approved
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

        func canMoveTo(_ next: ScheduledWitnessProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledWitnessProposalStatus.resolved
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ScheduledWitnessProposalStatus.archived
            case .reopened:
                return next == ScheduledWitnessProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledWitnessProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled witness proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return (Double(acuity) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledWitnessProposal {
            return ScheduledWitnessProposal(
                code: code,
                name: name,
                procedureCode: procedureCode,
                source: source,
                unit: unit,
                margin: margin,
                externalRef: externalRef,
                durationMinutes: durationMinutes,
                priority: priority,
                acuity: acuity,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled witness proposal in status open.
    static func newScheduledWitnessProposal(_ code: String, name: String) -> ScheduledWitnessProposal {
        return ScheduledWitnessProposal(
            code: code,
            name: name,
            procedureCode: "",
            source: "",
            unit: "",
            margin: 0.0,
            externalRef: "",
            durationMinutes: 0,
            priority: 0,
            acuity: 0,
            approved: false,
            status: ScheduledWitnessProposalStatus.`open`
        )
    }
}
