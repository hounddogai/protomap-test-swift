import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal slot mapping is in its life cycle.
    enum SeasonalSlotMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A seasonal slot mapping as the slot team keeps it.
    final class SeasonalSlotMapping {
        var code: String
        var name: String
        var refills: Int
        var currency: String
        var endsAt: Int
        var status: SeasonalSlotMappingStatus

        init(code: String, name: String, refills: Int, currency: String, endsAt: Int, status: SeasonalSlotMappingStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.currency = currency
            self.endsAt = endsAt
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

        func canMoveTo(_ next: SeasonalSlotMappingStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == SeasonalSlotMappingStatus.ready
            case .ready:
                return next == SeasonalSlotMappingStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: SeasonalSlotMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal slot mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal slot mapping") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(endsAt) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSlotMapping {
            return SeasonalSlotMapping(
                code: code,
                name: name,
                refills: refills,
                currency: currency,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal slot mapping in status idle.
    static func newSeasonalSlotMapping(_ code: String, name: String) -> SeasonalSlotMapping {
        return SeasonalSlotMapping(
            code: code,
            name: name,
            refills: 0,
            currency: "",
            endsAt: 0,
            status: SeasonalSlotMappingStatus.idle
        )
    }
}
