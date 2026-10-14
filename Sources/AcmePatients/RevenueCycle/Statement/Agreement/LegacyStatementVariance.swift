import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy statement variance is in its life cycle.
    enum LegacyStatementVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One legacy statement variance, with what the planners need to act on it.
    final class LegacyStatementVariance {
        var code: String
        var label: String
        var phone: String
        var active: Bool
        var payer: String
        var pinned: Bool
        var archived: Bool
        var floorValue: Double
        var status: LegacyStatementVarianceStatus

        init(code: String, label: String, phone: String, active: Bool, payer: String, pinned: Bool, archived: Bool, floorValue: Double, status: LegacyStatementVarianceStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.active = active
            self.payer = payer
            self.pinned = pinned
            self.archived = archived
            self.floorValue = floorValue
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

        func canMoveTo(_ next: LegacyStatementVarianceStatus) -> Bool {
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
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LegacyStatementVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy statement variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> LegacyStatementVariance {
            return LegacyStatementVariance(
                code: code,
                label: label,
                phone: phone,
                active: active,
                payer: payer,
                pinned: pinned,
                archived: archived,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy statement variance in status created.
    static func newLegacyStatementVariance(_ code: String, label: String) -> LegacyStatementVariance {
        return LegacyStatementVariance(
            code: code,
            label: label,
            phone: "",
            active: false,
            payer: "",
            pinned: false,
            archived: false,
            floorValue: 0.0,
            status: LegacyStatementVarianceStatus.created
        )
    }
}
