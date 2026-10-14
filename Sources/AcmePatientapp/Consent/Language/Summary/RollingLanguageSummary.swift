import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling language summary is in its life cycle.
    enum RollingLanguageSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling language summary as the language team keeps it.
    final class RollingLanguageSummary {
        var code: String
        var label: String
        var batchSize: Int
        var acuity: Int
        var facility: String
        var endsAt: Int
        var locale: String
        var visitMinutes: Int
        var status: RollingLanguageSummaryStatus

        init(code: String, label: String, batchSize: Int, acuity: Int, facility: String, endsAt: Int, locale: String, visitMinutes: Int, status: RollingLanguageSummaryStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.acuity = acuity
            self.facility = facility
            self.endsAt = endsAt
            self.locale = locale
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: RollingLanguageSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RollingLanguageSummaryStatus.failed
            case .running:
                return next == RollingLanguageSummaryStatus.done || next == RollingLanguageSummaryStatus.failed
            case .done:
                return next == RollingLanguageSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingLanguageSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling language summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedExposure() -> Double {
            return ((Double(endsAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RollingLanguageSummary {
            return RollingLanguageSummary(
                code: code,
                label: label,
                batchSize: batchSize,
                acuity: acuity,
                facility: facility,
                endsAt: endsAt,
                locale: locale,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rolling language summary in status new.
    static func newRollingLanguageSummary(_ code: String, label: String) -> RollingLanguageSummary {
        return RollingLanguageSummary(
            code: code,
            label: label,
            batchSize: 0,
            acuity: 0,
            facility: "",
            endsAt: 0,
            locale: "",
            visitMinutes: 0,
            status: RollingLanguageSummaryStatus.new
        )
    }
}
