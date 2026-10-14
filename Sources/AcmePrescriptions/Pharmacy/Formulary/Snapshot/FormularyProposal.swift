import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary proposal is in its life cycle.
    enum FormularyProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a formulary proposal and its current status.
    final class FormularyProposal {
        var code: String
        var name: String
        var minimum: Double
        var description: String
        var durationMinutes: Int
        var floorValue: Double
        var segment: String
        var title: String
        var status: FormularyProposalStatus

        init(code: String, name: String, minimum: Double, description: String, durationMinutes: Int, floorValue: Double, segment: String, title: String, status: FormularyProposalStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.description = description
            self.durationMinutes = durationMinutes
            self.floorValue = floorValue
            self.segment = segment
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FormularyProposalStatus) -> Bool {
            switch status {
            case .draft:
                return next == FormularyProposalStatus.active
            case .pending:
                return next == FormularyProposalStatus.suspended || next == FormularyProposalStatus.closed
            case .active:
                return next == FormularyProposalStatus.suspended || next == FormularyProposalStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: FormularyProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedValue() -> Double {
            return ((Double(durationMinutes) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> FormularyProposal {
            return FormularyProposal(
                code: code,
                name: name,
                minimum: minimum,
                description: description,
                durationMinutes: durationMinutes,
                floorValue: floorValue,
                segment: segment,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a formulary proposal in status draft.
    static func newFormularyProposal(_ code: String, name: String) -> FormularyProposal {
        return FormularyProposal(
            code: code,
            name: name,
            minimum: 0.0,
            description: "",
            durationMinutes: 0,
            floorValue: 0.0,
            segment: "",
            title: "",
            status: FormularyProposalStatus.draft
        )
    }
}
