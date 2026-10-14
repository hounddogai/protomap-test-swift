import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback task manifest is in its life cycle.
    enum FallbackTaskManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback task manifest as the task team keeps it.
    final class FallbackTaskManifest {
        var code: String
        var name: String
        var batchSize: Int
        var archived: Bool
        var ratio: Double
        var margin: Double
        var budget: Double
        var facility: String
        var startsAt: Int
        var allergy: String
        var status: FallbackTaskManifestStatus

        init(code: String, name: String, batchSize: Int, archived: Bool, ratio: Double, margin: Double, budget: Double, facility: String, startsAt: Int, allergy: String, status: FallbackTaskManifestStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.archived = archived
            self.ratio = ratio
            self.margin = margin
            self.budget = budget
            self.facility = facility
            self.startsAt = startsAt
            self.allergy = allergy
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

        func canMoveTo(_ next: FallbackTaskManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == FallbackTaskManifestStatus.retired
            case .validated:
                return next == FallbackTaskManifestStatus.published || next == FallbackTaskManifestStatus.retired
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

        func moveTo(_ next: FallbackTaskManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback task manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedTotal() -> Double {
            return ((margin + budget) * 100).rounded() / 100
        }

        func copyValue() -> FallbackTaskManifest {
            return FallbackTaskManifest(
                code: code,
                name: name,
                batchSize: batchSize,
                archived: archived,
                ratio: ratio,
                margin: margin,
                budget: budget,
                facility: facility,
                startsAt: startsAt,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback task manifest in status created.
    static func newFallbackTaskManifest(_ code: String, name: String) -> FallbackTaskManifest {
        return FallbackTaskManifest(
            code: code,
            name: name,
            batchSize: 0,
            archived: false,
            ratio: 0.0,
            margin: 0.0,
            budget: 0.0,
            facility: "",
            startsAt: 0,
            allergy: "",
            status: FallbackTaskManifestStatus.created
        )
    }
}
