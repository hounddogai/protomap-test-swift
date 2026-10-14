import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary remittance summary is in its life cycle.
    enum PrimaryRemittanceSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One primary remittance summary, with what the planners need to act on it.
    final class PrimaryRemittanceSummary {
        var code: String
        var label: String
        var diagnosisCode: String
        var unit: String
        var refills: Int
        var batchSize: Int
        var graceDays: Int
        var version: Int
        var pinned: Bool
        var status: PrimaryRemittanceSummaryStatus

        init(code: String, label: String, diagnosisCode: String, unit: String, refills: Int, batchSize: Int, graceDays: Int, version: Int, pinned: Bool, status: PrimaryRemittanceSummaryStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.unit = unit
            self.refills = refills
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.version = version
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryRemittanceSummaryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryRemittanceSummaryStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PrimaryRemittanceSummaryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryRemittanceSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary remittance summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("primary remittance summary") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(version) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRemittanceSummary {
            return PrimaryRemittanceSummary(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                unit: unit,
                refills: refills,
                batchSize: batchSize,
                graceDays: graceDays,
                version: version,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary remittance summary in status proposed.
    static func newPrimaryRemittanceSummary(_ code: String, label: String) -> PrimaryRemittanceSummary {
        return PrimaryRemittanceSummary(
            code: code,
            label: label,
            diagnosisCode: "",
            unit: "",
            refills: 0,
            batchSize: 0,
            graceDays: 0,
            version: 0,
            pinned: false,
            status: PrimaryRemittanceSummaryStatus.proposed
        )
    }
}
