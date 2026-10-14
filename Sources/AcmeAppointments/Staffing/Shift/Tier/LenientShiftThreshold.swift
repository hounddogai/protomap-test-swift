import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient shift threshold is in its life cycle.
    enum LenientShiftThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a lenient shift threshold and its current status.
    final class LenientShiftThreshold {
        var code: String
        var name: String
        var batchSize: Int
        var timezone: String
        var region: String
        var quantity: Int
        var bed: String
        var locale: String
        var status: LenientShiftThresholdStatus

        init(code: String, name: String, batchSize: Int, timezone: String, region: String, quantity: Int, bed: String, locale: String, status: LenientShiftThresholdStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.timezone = timezone
            self.region = region
            self.quantity = quantity
            self.bed = bed
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

        func canMoveTo(_ next: LenientShiftThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LenientShiftThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient shift threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient shift threshold") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(quantity) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> LenientShiftThreshold {
            return LenientShiftThreshold(
                code: code,
                name: name,
                batchSize: batchSize,
                timezone: timezone,
                region: region,
                quantity: quantity,
                bed: bed,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient shift threshold in status proposed.
    static func newLenientShiftThreshold(_ code: String, name: String) -> LenientShiftThreshold {
        return LenientShiftThreshold(
            code: code,
            name: name,
            batchSize: 0,
            timezone: "",
            region: "",
            quantity: 0,
            bed: "",
            locale: "",
            status: LenientShiftThresholdStatus.proposed
        )
    }
}
