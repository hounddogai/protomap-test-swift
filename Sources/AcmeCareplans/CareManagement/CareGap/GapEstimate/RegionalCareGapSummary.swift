import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional care gap summary is in its life cycle.
    enum RegionalCareGapSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A regional care gap summary as the care gap team keeps it.
    final class RegionalCareGapSummary {
        var code: String
        var label: String
        var threshold: Double
        var updatedAt: Int
        var refills: Int
        var margin: Double
        var revision: Int
        var timezone: String
        var procedureCode: String
        var windowDays: Int
        var locale: String
        var status: RegionalCareGapSummaryStatus

        init(code: String, label: String, threshold: Double, updatedAt: Int, refills: Int, margin: Double, revision: Int, timezone: String, procedureCode: String, windowDays: Int, locale: String, status: RegionalCareGapSummaryStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.updatedAt = updatedAt
            self.refills = refills
            self.margin = margin
            self.revision = revision
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.windowDays = windowDays
            self.locale = locale
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

        func canMoveTo(_ next: RegionalCareGapSummaryStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalCareGapSummaryStatus.done || next == RegionalCareGapSummaryStatus.failed
            case .queued:
                return next == RegionalCareGapSummaryStatus.running || next == RegionalCareGapSummaryStatus.done
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: RegionalCareGapSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care gap summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("regional care gap summary") \(code)"
        }

        func netTotal() -> Double {
            return (Double(updatedAt) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCareGapSummary {
            return RegionalCareGapSummary(
                code: code,
                label: label,
                threshold: threshold,
                updatedAt: updatedAt,
                refills: refills,
                margin: margin,
                revision: revision,
                timezone: timezone,
                procedureCode: procedureCode,
                windowDays: windowDays,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional care gap summary in status new.
    static func newRegionalCareGapSummary(_ code: String, label: String) -> RegionalCareGapSummary {
        return RegionalCareGapSummary(
            code: code,
            label: label,
            threshold: 0.0,
            updatedAt: 0,
            refills: 0,
            margin: 0.0,
            revision: 0,
            timezone: "",
            procedureCode: "",
            windowDays: 0,
            locale: "",
            status: RegionalCareGapSummaryStatus.new
        )
    }
}
