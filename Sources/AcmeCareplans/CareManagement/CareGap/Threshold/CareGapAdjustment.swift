import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap adjustment is in its life cycle.
    enum CareGapAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A care gap adjustment as the care gap team keeps it.
    final class CareGapAdjustment {
        var code: String
        var label: String
        var source: String
        var version: Int
        var currency: String
        var status: CareGapAdjustmentStatus

        init(code: String, label: String, source: String, version: Int, currency: String, status: CareGapAdjustmentStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.version = version
            self.currency = currency
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

        func canMoveTo(_ next: CareGapAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
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
                return next == CareGapAdjustmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("care gap adjustment") \(code)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> CareGapAdjustment {
            return CareGapAdjustment(
                code: code,
                label: label,
                source: source,
                version: version,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a care gap adjustment in status new.
    static func newCareGapAdjustment(_ code: String, label: String) -> CareGapAdjustment {
        return CareGapAdjustment(
            code: code,
            label: label,
            source: "",
            version: 0,
            currency: "",
            status: CareGapAdjustmentStatus.new
        )
    }
}
