import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal outreach digest is in its life cycle.
    enum SeasonalOutreachDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One seasonal outreach digest, with what the planners need to act on it.
    final class SeasonalOutreachDigest {
        var code: String
        var name: String
        var windowDays: Int
        var createdAt: Int
        var margin: Double
        var acuity: Int
        var label: String
        var capacity: Int
        var priority: Int
        var bed: String
        var status: SeasonalOutreachDigestStatus

        init(code: String, name: String, windowDays: Int, createdAt: Int, margin: Double, acuity: Int, label: String, capacity: Int, priority: Int, bed: String, status: SeasonalOutreachDigestStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.createdAt = createdAt
            self.margin = margin
            self.acuity = acuity
            self.label = label
            self.capacity = capacity
            self.priority = priority
            self.bed = bed
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

        func canMoveTo(_ next: SeasonalOutreachDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalOutreachDigestStatus.done || next == SeasonalOutreachDigestStatus.failed
            case .queued:
                return next == SeasonalOutreachDigestStatus.done || next == SeasonalOutreachDigestStatus.failed
            case .running:
                return next == SeasonalOutreachDigestStatus.done || next == SeasonalOutreachDigestStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: SeasonalOutreachDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal outreach digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("seasonal outreach digest") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(createdAt) * margin * 100).rounded() / 100
        }

        func copyValue() -> SeasonalOutreachDigest {
            return SeasonalOutreachDigest(
                code: code,
                name: name,
                windowDays: windowDays,
                createdAt: createdAt,
                margin: margin,
                acuity: acuity,
                label: label,
                capacity: capacity,
                priority: priority,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal outreach digest in status new.
    static func newSeasonalOutreachDigest(_ code: String, name: String) -> SeasonalOutreachDigest {
        return SeasonalOutreachDigest(
            code: code,
            name: name,
            windowDays: 0,
            createdAt: 0,
            margin: 0.0,
            acuity: 0,
            label: "",
            capacity: 0,
            priority: 0,
            bed: "",
            status: SeasonalOutreachDigestStatus.new
        )
    }
}
