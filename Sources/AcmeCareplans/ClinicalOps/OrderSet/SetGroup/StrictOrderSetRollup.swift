import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict order set rollup is in its life cycle.
    enum StrictOrderSetRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A strict order set rollup as the order set team keeps it.
    final class StrictOrderSetRollup {
        var code: String
        var label: String
        var locale: String
        var ceiling: Double
        var floorValue: Double
        var copay: Double
        var title: String
        var endsAt: Int
        var ownerID: String
        var status: StrictOrderSetRollupStatus

        init(code: String, label: String, locale: String, ceiling: Double, floorValue: Double, copay: Double, title: String, endsAt: Int, ownerID: String, status: StrictOrderSetRollupStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.ceiling = ceiling
            self.floorValue = floorValue
            self.copay = copay
            self.title = title
            self.endsAt = endsAt
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictOrderSetRollupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == StrictOrderSetRollupStatus.ready || next == StrictOrderSetRollupStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == StrictOrderSetRollupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictOrderSetRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict order set rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return ((floorValue - copay) * 100).rounded() / 100
        }

        func copyValue() -> StrictOrderSetRollup {
            return StrictOrderSetRollup(
                code: code,
                label: label,
                locale: locale,
                ceiling: ceiling,
                floorValue: floorValue,
                copay: copay,
                title: title,
                endsAt: endsAt,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict order set rollup in status idle.
    static func newStrictOrderSetRollup(_ code: String, label: String) -> StrictOrderSetRollup {
        return StrictOrderSetRollup(
            code: code,
            label: label,
            locale: "",
            ceiling: 0.0,
            floorValue: 0.0,
            copay: 0.0,
            title: "",
            endsAt: 0,
            ownerID: "",
            status: StrictOrderSetRollupStatus.idle
        )
    }
}
