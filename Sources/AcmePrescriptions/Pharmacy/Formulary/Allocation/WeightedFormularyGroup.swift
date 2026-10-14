import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted formulary group is in its life cycle.
    enum WeightedFormularyGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One weighted formulary group, with what the planners need to act on it.
    final class WeightedFormularyGroup {
        var code: String
        var label: String
        var currency: String
        var score: Double
        var tags: [String]
        var summary: String
        var ceiling: Double
        var specialty: String
        var approved: Bool
        var name: String
        var createdAt: Int
        var status: WeightedFormularyGroupStatus

        init(code: String, label: String, currency: String, score: Double, tags: [String], summary: String, ceiling: Double, specialty: String, approved: Bool, name: String, createdAt: Int, status: WeightedFormularyGroupStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.score = score
            self.tags = tags
            self.summary = summary
            self.ceiling = ceiling
            self.specialty = specialty
            self.approved = approved
            self.name = name
            self.createdAt = createdAt
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

        func canMoveTo(_ next: WeightedFormularyGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedFormularyGroupStatus.pending || next == WeightedFormularyGroupStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
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

        func moveTo(_ next: WeightedFormularyGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted formulary group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("weighted formulary group") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return ((ceiling + score) * 100).rounded() / 100
        }

        func copyValue() -> WeightedFormularyGroup {
            return WeightedFormularyGroup(
                code: code,
                label: label,
                currency: currency,
                score: score,
                tags: tags,
                summary: summary,
                ceiling: ceiling,
                specialty: specialty,
                approved: approved,
                name: name,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted formulary group in status draft.
    static func newWeightedFormularyGroup(_ code: String, label: String) -> WeightedFormularyGroup {
        return WeightedFormularyGroup(
            code: code,
            label: label,
            currency: "",
            score: 0.0,
            tags: [],
            summary: "",
            ceiling: 0.0,
            specialty: "",
            approved: false,
            name: "",
            createdAt: 0,
            status: WeightedFormularyGroupStatus.draft
        )
    }
}
