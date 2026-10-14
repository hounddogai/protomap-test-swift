import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy inventory manifest is in its life cycle.
    enum LegacyInventoryManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a legacy inventory manifest and its current status.
    final class LegacyInventoryManifest {
        var code: String
        var label: String
        var reviewer: String
        var diagnosisCode: String
        var rate: Double
        var timezone: String
        var source: String
        var status: LegacyInventoryManifestStatus

        init(code: String, label: String, reviewer: String, diagnosisCode: String, rate: Double, timezone: String, source: String, status: LegacyInventoryManifestStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.timezone = timezone
            self.source = source
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

        func canMoveTo(_ next: LegacyInventoryManifestStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyInventoryManifestStatus.running
            case .queued:
                return next == LegacyInventoryManifestStatus.running
            case .running:
                return next == LegacyInventoryManifestStatus.failed
            case .done:
                return next == LegacyInventoryManifestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyInventoryManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy inventory manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy inventory manifest") \(code)"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> LegacyInventoryManifest {
            return LegacyInventoryManifest(
                code: code,
                label: label,
                reviewer: reviewer,
                diagnosisCode: diagnosisCode,
                rate: rate,
                timezone: timezone,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a legacy inventory manifest in status new.
    static func newLegacyInventoryManifest(_ code: String, label: String) -> LegacyInventoryManifest {
        return LegacyInventoryManifest(
            code: code,
            label: label,
            reviewer: "",
            diagnosisCode: "",
            rate: 0.0,
            timezone: "",
            source: "",
            status: LegacyInventoryManifestStatus.new
        )
    }
}
