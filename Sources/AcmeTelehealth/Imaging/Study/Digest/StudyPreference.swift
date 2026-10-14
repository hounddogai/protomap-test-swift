import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study preference is in its life cycle.
    enum StudyPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a study preference and its current status.
    final class StudyPreference {
        var code: String
        var name: String
        var weight: Double
        var limit: Int
        var archived: Bool
        var payer: String
        var maximum: Double
        var version: Int
        var ratio: Double
        var budget: Double
        var startsAt: Int
        var status: StudyPreferenceStatus

        init(code: String, name: String, weight: Double, limit: Int, archived: Bool, payer: String, maximum: Double, version: Int, ratio: Double, budget: Double, startsAt: Int, status: StudyPreferenceStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.limit = limit
            self.archived = archived
            self.payer = payer
            self.maximum = maximum
            self.version = version
            self.ratio = ratio
            self.budget = budget
            self.startsAt = startsAt
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

        func canMoveTo(_ next: StudyPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == StudyPreferenceStatus.suspended || next == StudyPreferenceStatus.closed
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

        func moveTo(_ next: StudyPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return (budget * maximum * 100).rounded() / 100
        }

        func copyValue() -> StudyPreference {
            return StudyPreference(
                code: code,
                name: name,
                weight: weight,
                limit: limit,
                archived: archived,
                payer: payer,
                maximum: maximum,
                version: version,
                ratio: ratio,
                budget: budget,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a study preference in status draft.
    static func newStudyPreference(_ code: String, name: String) -> StudyPreference {
        return StudyPreference(
            code: code,
            name: name,
            weight: 0.0,
            limit: 0,
            archived: false,
            payer: "",
            maximum: 0.0,
            version: 0,
            ratio: 0.0,
            budget: 0.0,
            startsAt: 0,
            status: StudyPreferenceStatus.draft
        )
    }
}
