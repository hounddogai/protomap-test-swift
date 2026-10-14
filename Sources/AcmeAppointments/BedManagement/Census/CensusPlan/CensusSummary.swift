import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census summary is in its life cycle.
    enum CensusSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One census summary, with what the planners need to act on it.
    final class CensusSummary {
        var code: String
        var label: String
        var allergy: String
        var country: String
        var priority: Int
        var title: String
        var specialty: String
        var score: Double
        var batchSize: Int
        var status: CensusSummaryStatus

        init(code: String, label: String, allergy: String, country: String, priority: Int, title: String, specialty: String, score: Double, batchSize: Int, status: CensusSummaryStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.country = country
            self.priority = priority
            self.title = title
            self.specialty = specialty
            self.score = score
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CensusSummaryStatus.ready || next == CensusSummaryStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CensusSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return (score * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> CensusSummary {
            return CensusSummary(
                code: code,
                label: label,
                allergy: allergy,
                country: country,
                priority: priority,
                title: title,
                specialty: specialty,
                score: score,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a census summary in status idle.
    static func newCensusSummary(_ code: String, label: String) -> CensusSummary {
        return CensusSummary(
            code: code,
            label: label,
            allergy: "",
            country: "",
            priority: 0,
            title: "",
            specialty: "",
            score: 0.0,
            batchSize: 0,
            status: CensusSummaryStatus.idle
        )
    }
}
