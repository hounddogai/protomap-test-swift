import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial checkpoint is in its life cycle.
    enum DenialCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a denial checkpoint and its current status.
    final class DenialCheckpoint {
        var code: String
        var name: String
        var weight: Double
        var checksum: String
        var allergy: String
        var budget: Double
        var archived: Bool
        var updatedAt: Int
        var summary: String
        var locale: String
        var status: DenialCheckpointStatus

        init(code: String, name: String, weight: Double, checksum: String, allergy: String, budget: Double, archived: Bool, updatedAt: Int, summary: String, locale: String, status: DenialCheckpointStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.checksum = checksum
            self.allergy = allergy
            self.budget = budget
            self.archived = archived
            self.updatedAt = updatedAt
            self.summary = summary
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DenialCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DenialCheckpointStatus.archived
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DenialCheckpointStatus.reopened || next == DenialCheckpointStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: DenialCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("denial checkpoint") \(code)"
        }

        func netExposure() -> Double {
            return ((weight + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> DenialCheckpoint {
            return DenialCheckpoint(
                code: code,
                name: name,
                weight: weight,
                checksum: checksum,
                allergy: allergy,
                budget: budget,
                archived: archived,
                updatedAt: updatedAt,
                summary: summary,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a denial checkpoint in status open.
    static func newDenialCheckpoint(_ code: String, name: String) -> DenialCheckpoint {
        return DenialCheckpoint(
            code: code,
            name: name,
            weight: 0.0,
            checksum: "",
            allergy: "",
            budget: 0.0,
            archived: false,
            updatedAt: 0,
            summary: "",
            locale: "",
            status: DenialCheckpointStatus.`open`
        )
    }
}
