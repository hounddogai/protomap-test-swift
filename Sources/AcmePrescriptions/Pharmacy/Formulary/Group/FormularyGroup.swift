import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary group is in its life cycle.
    enum FormularyGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One formulary group, with what the planners need to act on it.
    final class FormularyGroup {
        var code: String
        var name: String
        var endsAt: Int
        var tags: [String]
        var score: Double
        var allergy: String
        var budget: Double
        var checksum: String
        var diagnosisCode: String
        var summary: String
        var status: FormularyGroupStatus

        init(code: String, name: String, endsAt: Int, tags: [String], score: Double, allergy: String, budget: Double, checksum: String, diagnosisCode: String, summary: String, status: FormularyGroupStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.tags = tags
            self.score = score
            self.allergy = allergy
            self.budget = budget
            self.checksum = checksum
            self.diagnosisCode = diagnosisCode
            self.summary = summary
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

        func canMoveTo(_ next: FormularyGroupStatus) -> Bool {
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
                return next == FormularyGroupStatus.published || next == FormularyGroupStatus.retired
            case .published:
                return next == FormularyGroupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((score + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> FormularyGroup {
            return FormularyGroup(
                code: code,
                name: name,
                endsAt: endsAt,
                tags: tags,
                score: score,
                allergy: allergy,
                budget: budget,
                checksum: checksum,
                diagnosisCode: diagnosisCode,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a formulary group in status created.
    static func newFormularyGroup(_ code: String, name: String) -> FormularyGroup {
        return FormularyGroup(
            code: code,
            name: name,
            endsAt: 0,
            tags: [],
            score: 0.0,
            allergy: "",
            budget: 0.0,
            checksum: "",
            diagnosisCode: "",
            summary: "",
            status: FormularyGroupStatus.created
        )
    }
}
