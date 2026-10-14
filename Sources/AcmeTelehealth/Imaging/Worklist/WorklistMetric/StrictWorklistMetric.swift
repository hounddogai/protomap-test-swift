import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict worklist metric is in its life cycle.
    enum StrictWorklistMetricStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A strict worklist metric. Its code is unique within a tenant.
    final class StrictWorklistMetric {
        var code: String
        var title: String
        var encounterID: String
        var description: String
        var externalRef: String
        var threshold: Double
        var startsAt: Int
        var status: StrictWorklistMetricStatus

        init(code: String, title: String, encounterID: String, description: String, externalRef: String, threshold: Double, startsAt: Int, status: StrictWorklistMetricStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.description = description
            self.externalRef = externalRef
            self.threshold = threshold
            self.startsAt = startsAt
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

        func canMoveTo(_ next: StrictWorklistMetricStatus) -> Bool {
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
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == StrictWorklistMetricStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictWorklistMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict worklist metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return ((threshold + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictWorklistMetric {
            return StrictWorklistMetric(
                code: code,
                title: title,
                encounterID: encounterID,
                description: description,
                externalRef: externalRef,
                threshold: threshold,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict worklist metric in status created.
    static func newStrictWorklistMetric(_ code: String, title: String) -> StrictWorklistMetric {
        return StrictWorklistMetric(
            code: code,
            title: title,
            encounterID: "",
            description: "",
            externalRef: "",
            threshold: 0.0,
            startsAt: 0,
            status: StrictWorklistMetricStatus.created
        )
    }
}
