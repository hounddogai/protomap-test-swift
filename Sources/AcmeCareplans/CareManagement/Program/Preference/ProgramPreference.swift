import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program preference is in its life cycle.
    enum ProgramPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A program preference as the program team keeps it.
    final class ProgramPreference {
        var code: String
        var title: String
        var summary: String
        var threshold: Double
        var dosageMg: Double
        var reviewer: String
        var durationMinutes: Int
        var tags: [String]
        var status: ProgramPreferenceStatus

        init(code: String, title: String, summary: String, threshold: Double, dosageMg: Double, reviewer: String, durationMinutes: Int, tags: [String], status: ProgramPreferenceStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.tags = tags
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

        func canMoveTo(_ next: ProgramPreferenceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ProgramPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return ((Double(durationMinutes) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> ProgramPreference {
            return ProgramPreference(
                code: code,
                title: title,
                summary: summary,
                threshold: threshold,
                dosageMg: dosageMg,
                reviewer: reviewer,
                durationMinutes: durationMinutes,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a program preference in status created.
    static func newProgramPreference(_ code: String, title: String) -> ProgramPreference {
        return ProgramPreference(
            code: code,
            title: title,
            summary: "",
            threshold: 0.0,
            dosageMg: 0.0,
            reviewer: "",
            durationMinutes: 0,
            tags: [],
            status: ProgramPreferenceStatus.created
        )
    }
}
