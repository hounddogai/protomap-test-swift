import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback formulary proposal is in its life cycle.
    enum FallbackFormularyProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback formulary proposal as the formulary team keeps it.
    final class FallbackFormularyProposal {
        var code: String
        var name: String
        var reviewer: String
        var archived: Bool
        var priority: Int
        var dosageMg: Double
        var weight: Double
        var facility: String
        var status: FallbackFormularyProposalStatus

        init(code: String, name: String, reviewer: String, archived: Bool, priority: Int, dosageMg: Double, weight: Double, facility: String, status: FallbackFormularyProposalStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.archived = archived
            self.priority = priority
            self.dosageMg = dosageMg
            self.weight = weight
            self.facility = facility
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

        func canMoveTo(_ next: FallbackFormularyProposalStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FallbackFormularyProposalStatus.failed
            case .running:
                return next == FallbackFormularyProposalStatus.done
            case .done:
                return next == FallbackFormularyProposalStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackFormularyProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback formulary proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return ((weight + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> FallbackFormularyProposal {
            return FallbackFormularyProposal(
                code: code,
                name: name,
                reviewer: reviewer,
                archived: archived,
                priority: priority,
                dosageMg: dosageMg,
                weight: weight,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback formulary proposal in status new.
    static func newFallbackFormularyProposal(_ code: String, name: String) -> FallbackFormularyProposal {
        return FallbackFormularyProposal(
            code: code,
            name: name,
            reviewer: "",
            archived: false,
            priority: 0,
            dosageMg: 0.0,
            weight: 0.0,
            facility: "",
            status: FallbackFormularyProposalStatus.new
        )
    }
}
