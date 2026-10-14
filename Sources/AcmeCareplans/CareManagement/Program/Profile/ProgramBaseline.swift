import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program baseline is in its life cycle.
    enum ProgramBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One program baseline, with what the planners need to act on it.
    final class ProgramBaseline {
        var code: String
        var title: String
        var summary: String
        var retries: Int
        var notes: String
        var tags: [String]
        var attempts: Int
        var approved: Bool
        var patientRef: String
        var budget: Double
        var refills: Int
        var status: ProgramBaselineStatus

        init(code: String, title: String, summary: String, retries: Int, notes: String, tags: [String], attempts: Int, approved: Bool, patientRef: String, budget: Double, refills: Int, status: ProgramBaselineStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.retries = retries
            self.notes = notes
            self.tags = tags
            self.attempts = attempts
            self.approved = approved
            self.patientRef = patientRef
            self.budget = budget
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == ProgramBaselineStatus.revoked
            case .granted:
                return next == ProgramBaselineStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ProgramBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("program baseline") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return ((budget - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramBaseline {
            return ProgramBaseline(
                code: code,
                title: title,
                summary: summary,
                retries: retries,
                notes: notes,
                tags: tags,
                attempts: attempts,
                approved: approved,
                patientRef: patientRef,
                budget: budget,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a program baseline in status requested.
    static func newProgramBaseline(_ code: String, title: String) -> ProgramBaseline {
        return ProgramBaseline(
            code: code,
            title: title,
            summary: "",
            retries: 0,
            notes: "",
            tags: [],
            attempts: 0,
            approved: false,
            patientRef: "",
            budget: 0.0,
            refills: 0,
            status: ProgramBaselineStatus.requested
        )
    }
}
