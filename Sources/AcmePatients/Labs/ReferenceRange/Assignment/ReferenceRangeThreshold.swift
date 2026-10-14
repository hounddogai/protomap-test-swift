import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range threshold is in its life cycle.
    enum ReferenceRangeThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a reference range threshold and its current status.
    final class ReferenceRangeThreshold {
        var code: String
        var name: String
        var threshold: Double
        var refills: Int
        var externalRef: String
        var payer: String
        var windowDays: Int
        var locale: String
        var status: ReferenceRangeThresholdStatus

        init(code: String, name: String, threshold: Double, refills: Int, externalRef: String, payer: String, windowDays: Int, locale: String, status: ReferenceRangeThresholdStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.refills = refills
            self.externalRef = externalRef
            self.payer = payer
            self.windowDays = windowDays
            self.locale = locale
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

        func canMoveTo(_ next: ReferenceRangeThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ReferenceRangeThresholdStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ReferenceRangeThresholdStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedTotal() -> Double {
            return ((threshold - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeThreshold {
            return ReferenceRangeThreshold(
                code: code,
                name: name,
                threshold: threshold,
                refills: refills,
                externalRef: externalRef,
                payer: payer,
                windowDays: windowDays,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a reference range threshold in status proposed.
    static func newReferenceRangeThreshold(_ code: String, name: String) -> ReferenceRangeThreshold {
        return ReferenceRangeThreshold(
            code: code,
            name: name,
            threshold: 0.0,
            refills: 0,
            externalRef: "",
            payer: "",
            windowDays: 0,
            locale: "",
            status: ReferenceRangeThresholdStatus.proposed
        )
    }
}
