import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled denial baseline is in its life cycle.
    enum ScheduledDenialBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One scheduled denial baseline, with what the planners need to act on it.
    final class ScheduledDenialBaseline {
        var code: String
        var name: String
        var title: String
        var refills: Int
        var ward: String
        var visible: Bool
        var status: ScheduledDenialBaselineStatus

        init(code: String, name: String, title: String, refills: Int, ward: String, visible: Bool, status: ScheduledDenialBaselineStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.refills = refills
            self.ward = ward
            self.visible = visible
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

        func canMoveTo(_ next: ScheduledDenialBaselineStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ScheduledDenialBaselineStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledDenialBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled denial baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> ScheduledDenialBaseline {
            return ScheduledDenialBaseline(
                code: code,
                name: name,
                title: title,
                refills: refills,
                ward: ward,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled denial baseline in status new.
    static func newScheduledDenialBaseline(_ code: String, name: String) -> ScheduledDenialBaseline {
        return ScheduledDenialBaseline(
            code: code,
            name: name,
            title: "",
            refills: 0,
            ward: "",
            visible: false,
            status: ScheduledDenialBaselineStatus.new
        )
    }
}
