import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy interaction tier is in its life cycle.
    enum LegacyInteractionTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a legacy interaction tier and its current status.
    final class LegacyInteractionTier {
        var code: String
        var name: String
        var retries: Int
        var floorValue: Double
        var ratio: Double
        var phone: String
        var timezone: String
        var status: LegacyInteractionTierStatus

        init(code: String, name: String, retries: Int, floorValue: Double, ratio: Double, phone: String, timezone: String, status: LegacyInteractionTierStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.floorValue = floorValue
            self.ratio = ratio
            self.phone = phone
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyInteractionTierStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LegacyInteractionTierStatus.published || next == LegacyInteractionTierStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LegacyInteractionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy interaction tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netTotal() -> Double {
            return ((Double(retries) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> LegacyInteractionTier {
            return LegacyInteractionTier(
                code: code,
                name: name,
                retries: retries,
                floorValue: floorValue,
                ratio: ratio,
                phone: phone,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy interaction tier in status created.
    static func newLegacyInteractionTier(_ code: String, name: String) -> LegacyInteractionTier {
        return LegacyInteractionTier(
            code: code,
            name: name,
            retries: 0,
            floorValue: 0.0,
            ratio: 0.0,
            phone: "",
            timezone: "",
            status: LegacyInteractionTierStatus.created
        )
    }
}
