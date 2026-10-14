import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped revocation summary is in its life cycle.
    enum CappedRevocationSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a capped revocation summary and its current status.
    final class CappedRevocationSummary {
        var code: String
        var label: String
        var retries: Int
        var startsAt: Int
        var patientRef: String
        var endsAt: Int
        var unit: String
        var status: CappedRevocationSummaryStatus

        init(code: String, label: String, retries: Int, startsAt: Int, patientRef: String, endsAt: Int, unit: String, status: CappedRevocationSummaryStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.startsAt = startsAt
            self.patientRef = patientRef
            self.endsAt = endsAt
            self.unit = unit
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

        func canMoveTo(_ next: CappedRevocationSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CappedRevocationSummaryStatus.running || next == CappedRevocationSummaryStatus.done
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: CappedRevocationSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped revocation summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedLoad() -> Double {
            return ((Double(endsAt) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedRevocationSummary {
            return CappedRevocationSummary(
                code: code,
                label: label,
                retries: retries,
                startsAt: startsAt,
                patientRef: patientRef,
                endsAt: endsAt,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped revocation summary in status new.
    static func newCappedRevocationSummary(_ code: String, label: String) -> CappedRevocationSummary {
        return CappedRevocationSummary(
            code: code,
            label: label,
            retries: 0,
            startsAt: 0,
            patientRef: "",
            endsAt: 0,
            unit: "",
            status: CappedRevocationSummaryStatus.new
        )
    }
}
