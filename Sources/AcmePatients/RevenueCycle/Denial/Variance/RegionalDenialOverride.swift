import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional denial override is in its life cycle.
    enum RegionalDenialOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a regional denial override and its current status.
    final class RegionalDenialOverride {
        var code: String
        var title: String
        var procedureCode: String
        var bed: String
        var startsAt: Int
        var reviewer: String
        var threshold: Double
        var name: String
        var diagnosisCode: String
        var minimum: Double
        var capacity: Int
        var status: RegionalDenialOverrideStatus

        init(code: String, title: String, procedureCode: String, bed: String, startsAt: Int, reviewer: String, threshold: Double, name: String, diagnosisCode: String, minimum: Double, capacity: Int, status: RegionalDenialOverrideStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.bed = bed
            self.startsAt = startsAt
            self.reviewer = reviewer
            self.threshold = threshold
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.minimum = minimum
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalDenialOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalDenialOverrideStatus.running
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RegionalDenialOverrideStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalDenialOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional denial override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return ((minimum - threshold) * 100).rounded() / 100
        }

        func copyValue() -> RegionalDenialOverride {
            return RegionalDenialOverride(
                code: code,
                title: title,
                procedureCode: procedureCode,
                bed: bed,
                startsAt: startsAt,
                reviewer: reviewer,
                threshold: threshold,
                name: name,
                diagnosisCode: diagnosisCode,
                minimum: minimum,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional denial override in status new.
    static func newRegionalDenialOverride(_ code: String, title: String) -> RegionalDenialOverride {
        return RegionalDenialOverride(
            code: code,
            title: title,
            procedureCode: "",
            bed: "",
            startsAt: 0,
            reviewer: "",
            threshold: 0.0,
            name: "",
            diagnosisCode: "",
            minimum: 0.0,
            capacity: 0,
            status: RegionalDenialOverrideStatus.new
        )
    }
}
