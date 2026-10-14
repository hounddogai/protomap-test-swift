import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default denial cycle is in its life cycle.
    enum DefaultDenialCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default denial cycle. Its code is unique within a tenant.
    final class DefaultDenialCycle {
        var code: String
        var title: String
        var locale: String
        var unit: String
        var approved: Bool
        var windowDays: Int
        var status: DefaultDenialCycleStatus

        init(code: String, title: String, locale: String, unit: String, approved: Bool, windowDays: Int, status: DefaultDenialCycleStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.unit = unit
            self.approved = approved
            self.windowDays = windowDays
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

        func canMoveTo(_ next: DefaultDenialCycleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DefaultDenialCycleStatus.ready || next == DefaultDenialCycleStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DefaultDenialCycleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultDenialCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default denial cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> DefaultDenialCycle {
            return DefaultDenialCycle(
                code: code,
                title: title,
                locale: locale,
                unit: unit,
                approved: approved,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a default denial cycle in status idle.
    static func newDefaultDenialCycle(_ code: String, title: String) -> DefaultDenialCycle {
        return DefaultDenialCycle(
            code: code,
            title: title,
            locale: "",
            unit: "",
            approved: false,
            windowDays: 0,
            status: DefaultDenialCycleStatus.idle
        )
    }
}
