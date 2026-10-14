import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy census tier is in its life cycle.
    enum LegacyCensusTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy census tier. Its code is unique within a tenant.
    final class LegacyCensusTier {
        var code: String
        var label: String
        var windowDays: Int
        var startsAt: Int
        var batchSize: Int
        var threshold: Double
        var patientRef: String
        var status: LegacyCensusTierStatus

        init(code: String, label: String, windowDays: Int, startsAt: Int, batchSize: Int, threshold: Double, patientRef: String, status: LegacyCensusTierStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.batchSize = batchSize
            self.threshold = threshold
            self.patientRef = patientRef
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

        func canMoveTo(_ next: LegacyCensusTierStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyCensusTierStatus.done
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LegacyCensusTierStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCensusTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy census tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("legacy census tier") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(startsAt) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCensusTier {
            return LegacyCensusTier(
                code: code,
                label: label,
                windowDays: windowDays,
                startsAt: startsAt,
                batchSize: batchSize,
                threshold: threshold,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy census tier in status new.
    static func newLegacyCensusTier(_ code: String, label: String) -> LegacyCensusTier {
        return LegacyCensusTier(
            code: code,
            label: label,
            windowDays: 0,
            startsAt: 0,
            batchSize: 0,
            threshold: 0.0,
            patientRef: "",
            status: LegacyCensusTierStatus.new
        )
    }
}
