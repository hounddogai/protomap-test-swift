import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen tier is in its life cycle.
    enum SpecimenTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One specimen tier, with what the planners need to act on it.
    final class SpecimenTier {
        var code: String
        var label: String
        var capacity: Int
        var category: String
        var createdAt: Int
        var budget: Double
        var channel: String
        var clinicianID: String
        var archived: Bool
        var status: SpecimenTierStatus

        init(code: String, label: String, capacity: Int, category: String, createdAt: Int, budget: Double, channel: String, clinicianID: String, archived: Bool, status: SpecimenTierStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.category = category
            self.createdAt = createdAt
            self.budget = budget
            self.channel = channel
            self.clinicianID = clinicianID
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenTierStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == SpecimenTierStatus.completed
            case .completed:
                return next == SpecimenTierStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("specimen tier") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(createdAt) + budget) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenTier {
            return SpecimenTier(
                code: code,
                label: label,
                capacity: capacity,
                category: category,
                createdAt: createdAt,
                budget: budget,
                channel: channel,
                clinicianID: clinicianID,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a specimen tier in status planned.
    static func newSpecimenTier(_ code: String, label: String) -> SpecimenTier {
        return SpecimenTier(
            code: code,
            label: label,
            capacity: 0,
            category: "",
            createdAt: 0,
            budget: 0.0,
            channel: "",
            clinicianID: "",
            archived: false,
            status: SpecimenTierStatus.planned
        )
    }
}
