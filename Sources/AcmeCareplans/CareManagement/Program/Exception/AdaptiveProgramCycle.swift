import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive program cycle is in its life cycle.
    enum AdaptiveProgramCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive program cycle as the program team keeps it.
    final class AdaptiveProgramCycle {
        var code: String
        var name: String
        var payer: String
        var notes: String
        var refills: Int
        var diagnosisCode: String
        var tags: [String]
        var description: String
        var status: AdaptiveProgramCycleStatus

        init(code: String, name: String, payer: String, notes: String, refills: Int, diagnosisCode: String, tags: [String], description: String, status: AdaptiveProgramCycleStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.notes = notes
            self.refills = refills
            self.diagnosisCode = diagnosisCode
            self.tags = tags
            self.description = description
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

        func canMoveTo(_ next: AdaptiveProgramCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveProgramCycleStatus.suspended
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AdaptiveProgramCycleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveProgramCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive program cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> AdaptiveProgramCycle {
            return AdaptiveProgramCycle(
                code: code,
                name: name,
                payer: payer,
                notes: notes,
                refills: refills,
                diagnosisCode: diagnosisCode,
                tags: tags,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive program cycle in status draft.
    static func newAdaptiveProgramCycle(_ code: String, name: String) -> AdaptiveProgramCycle {
        return AdaptiveProgramCycle(
            code: code,
            name: name,
            payer: "",
            notes: "",
            refills: 0,
            diagnosisCode: "",
            tags: [],
            description: "",
            status: AdaptiveProgramCycleStatus.draft
        )
    }
}
