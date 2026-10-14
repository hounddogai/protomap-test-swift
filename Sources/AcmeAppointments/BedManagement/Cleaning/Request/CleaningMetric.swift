import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning metric is in its life cycle.
    enum CleaningMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A cleaning metric. Its code is unique within a tenant.
    final class CleaningMetric {
        var code: String
        var title: String
        var notes: String
        var country: String
        var contactEmail: String
        var windowDays: Int
        var ceiling: Double
        var version: Int
        var attempts: Int
        var bed: String
        var weight: Double
        var status: CleaningMetricStatus

        init(code: String, title: String, notes: String, country: String, contactEmail: String, windowDays: Int, ceiling: Double, version: Int, attempts: Int, bed: String, weight: Double, status: CleaningMetricStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.country = country
            self.contactEmail = contactEmail
            self.windowDays = windowDays
            self.ceiling = ceiling
            self.version = version
            self.attempts = attempts
            self.bed = bed
            self.weight = weight
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

        func canMoveTo(_ next: CleaningMetricStatus) -> Bool {
            switch status {
            case .new:
                return next == CleaningMetricStatus.queued
            case .queued:
                return next == CleaningMetricStatus.running || next == CleaningMetricStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CleaningMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("cleaning metric") \(code)"
        }

        func effectiveExposure() -> Double {
            return (ceiling * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> CleaningMetric {
            return CleaningMetric(
                code: code,
                title: title,
                notes: notes,
                country: country,
                contactEmail: contactEmail,
                windowDays: windowDays,
                ceiling: ceiling,
                version: version,
                attempts: attempts,
                bed: bed,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a cleaning metric in status new.
    static func newCleaningMetric(_ code: String, title: String) -> CleaningMetric {
        return CleaningMetric(
            code: code,
            title: title,
            notes: "",
            country: "",
            contactEmail: "",
            windowDays: 0,
            ceiling: 0.0,
            version: 0,
            attempts: 0,
            bed: "",
            weight: 0.0,
            status: CleaningMetricStatus.new
        )
    }
}
