import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual authorization rollup is in its life cycle.
    enum ManualAuthorizationRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual authorization rollup as the authorization team keeps it.
    final class ManualAuthorizationRollup {
        var code: String
        var label: String
        var ownerID: String
        var copay: Double
        var approved: Bool
        var maximum: Double
        var category: String
        var channel: String
        var segment: String
        var rate: Double
        var locale: String
        var status: ManualAuthorizationRollupStatus

        init(code: String, label: String, ownerID: String, copay: Double, approved: Bool, maximum: Double, category: String, channel: String, segment: String, rate: Double, locale: String, status: ManualAuthorizationRollupStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.copay = copay
            self.approved = approved
            self.maximum = maximum
            self.category = category
            self.channel = channel
            self.segment = segment
            self.rate = rate
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualAuthorizationRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualAuthorizationRollupStatus.active || next == ManualAuthorizationRollupStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ManualAuthorizationRollupStatus.suspended || next == ManualAuthorizationRollupStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ManualAuthorizationRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual authorization rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual authorization rollup") \(code)"
        }

        func weightedValue() -> Double {
            return ((maximum + copay) * 100).rounded() / 100
        }

        func copyValue() -> ManualAuthorizationRollup {
            return ManualAuthorizationRollup(
                code: code,
                label: label,
                ownerID: ownerID,
                copay: copay,
                approved: approved,
                maximum: maximum,
                category: category,
                channel: channel,
                segment: segment,
                rate: rate,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual authorization rollup in status draft.
    static func newManualAuthorizationRollup(_ code: String, label: String) -> ManualAuthorizationRollup {
        return ManualAuthorizationRollup(
            code: code,
            label: label,
            ownerID: "",
            copay: 0.0,
            approved: false,
            maximum: 0.0,
            category: "",
            channel: "",
            segment: "",
            rate: 0.0,
            locale: "",
            status: ManualAuthorizationRollupStatus.draft
        )
    }
}
