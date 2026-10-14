import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted study plan is in its life cycle.
    enum WeightedStudyPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a weighted study plan and its current status.
    final class WeightedStudyPlan {
        var code: String
        var label: String
        var floorValue: Double
        var revision: Int
        var summary: String
        var channel: String
        var weight: Double
        var pinned: Bool
        var clinicianID: String
        var segment: String
        var description: String
        var status: WeightedStudyPlanStatus

        init(code: String, label: String, floorValue: Double, revision: Int, summary: String, channel: String, weight: Double, pinned: Bool, clinicianID: String, segment: String, description: String, status: WeightedStudyPlanStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.revision = revision
            self.summary = summary
            self.channel = channel
            self.weight = weight
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.segment = segment
            self.description = description
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

        func canMoveTo(_ next: WeightedStudyPlanStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WeightedStudyPlanStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == WeightedStudyPlanStatus.reopened || next == WeightedStudyPlanStatus.archived
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

        func moveTo(_ next: WeightedStudyPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted study plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedVolume() -> Double {
            return ((Double(revision) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> WeightedStudyPlan {
            return WeightedStudyPlan(
                code: code,
                label: label,
                floorValue: floorValue,
                revision: revision,
                summary: summary,
                channel: channel,
                weight: weight,
                pinned: pinned,
                clinicianID: clinicianID,
                segment: segment,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted study plan in status open.
    static func newWeightedStudyPlan(_ code: String, label: String) -> WeightedStudyPlan {
        return WeightedStudyPlan(
            code: code,
            label: label,
            floorValue: 0.0,
            revision: 0,
            summary: "",
            channel: "",
            weight: 0.0,
            pinned: false,
            clinicianID: "",
            segment: "",
            description: "",
            status: WeightedStudyPlanStatus.`open`
        )
    }
}
