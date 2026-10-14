import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen metric is in its life cycle.
    enum SpecimenMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One specimen metric, with what the planners need to act on it.
    final class SpecimenMetric {
        var code: String
        var title: String
        var ownerID: String
        var encounterID: String
        var ratio: Double
        var cost: Double
        var notes: String
        var startsAt: Int
        var visible: Bool
        var label: String
        var status: SpecimenMetricStatus

        init(code: String, title: String, ownerID: String, encounterID: String, ratio: Double, cost: Double, notes: String, startsAt: Int, visible: Bool, label: String, status: SpecimenMetricStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.ratio = ratio
            self.cost = cost
            self.notes = notes
            self.startsAt = startsAt
            self.visible = visible
            self.label = label
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

        func canMoveTo(_ next: SpecimenMetricStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SpecimenMetricStatus.inReview || next == SpecimenMetricStatus.resolved
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == SpecimenMetricStatus.reopened || next == SpecimenMetricStatus.archived
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

        func moveTo(_ next: SpecimenMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("specimen metric") \(code)"
        }

        func netLoad() -> Double {
            return ((ratio + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenMetric {
            return SpecimenMetric(
                code: code,
                title: title,
                ownerID: ownerID,
                encounterID: encounterID,
                ratio: ratio,
                cost: cost,
                notes: notes,
                startsAt: startsAt,
                visible: visible,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a specimen metric in status open.
    static func newSpecimenMetric(_ code: String, title: String) -> SpecimenMetric {
        return SpecimenMetric(
            code: code,
            title: title,
            ownerID: "",
            encounterID: "",
            ratio: 0.0,
            cost: 0.0,
            notes: "",
            startsAt: 0,
            visible: false,
            label: "",
            status: SpecimenMetricStatus.`open`
        )
    }
}
