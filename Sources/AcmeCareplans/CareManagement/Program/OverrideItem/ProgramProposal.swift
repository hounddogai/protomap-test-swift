import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program proposal is in its life cycle.
    enum ProgramProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One program proposal, with what the planners need to act on it.
    final class ProgramProposal {
        var code: String
        var label: String
        var specialty: String
        var priority: Int
        var segment: String
        var currency: String
        var maximum: Double
        var archived: Bool
        var bed: String
        var status: ProgramProposalStatus

        init(code: String, label: String, specialty: String, priority: Int, segment: String, currency: String, maximum: Double, archived: Bool, bed: String, status: ProgramProposalStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.priority = priority
            self.segment = segment
            self.currency = currency
            self.maximum = maximum
            self.archived = archived
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramProposalStatus) -> Bool {
            switch status {
            case .idle:
                return next == ProgramProposalStatus.warming
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ProgramProposalStatus.draining || next == ProgramProposalStatus.stopped
            case .draining:
                return next == ProgramProposalStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedExposure() -> Double {
            return ((Double(priority) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ProgramProposal {
            return ProgramProposal(
                code: code,
                label: label,
                specialty: specialty,
                priority: priority,
                segment: segment,
                currency: currency,
                maximum: maximum,
                archived: archived,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a program proposal in status idle.
    static func newProgramProposal(_ code: String, label: String) -> ProgramProposal {
        return ProgramProposal(
            code: code,
            label: label,
            specialty: "",
            priority: 0,
            segment: "",
            currency: "",
            maximum: 0.0,
            archived: false,
            bed: "",
            status: ProgramProposalStatus.idle
        )
    }
}
