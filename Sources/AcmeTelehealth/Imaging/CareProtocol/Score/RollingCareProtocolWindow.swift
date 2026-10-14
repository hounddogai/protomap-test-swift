import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling care protocol window is in its life cycle.
    enum RollingCareProtocolWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rolling care protocol window and its current status.
    final class RollingCareProtocolWindow {
        var code: String
        var title: String
        var name: String
        var active: Bool
        var budget: Double
        var retries: Int
        var weight: Double
        var status: RollingCareProtocolWindowStatus

        init(code: String, title: String, name: String, active: Bool, budget: Double, retries: Int, weight: Double, status: RollingCareProtocolWindowStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.active = active
            self.budget = budget
            self.retries = retries
            self.weight = weight
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

        func canMoveTo(_ next: RollingCareProtocolWindowStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RollingCareProtocolWindowStatus.done
            case .done:
                return next == RollingCareProtocolWindowStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareProtocolWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care protocol window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling care protocol window") \(code)"
        }

        func weightedExposure() -> Double {
            return (budget * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareProtocolWindow {
            return RollingCareProtocolWindow(
                code: code,
                title: title,
                name: name,
                active: active,
                budget: budget,
                retries: retries,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling care protocol window in status new.
    static func newRollingCareProtocolWindow(_ code: String, title: String) -> RollingCareProtocolWindow {
        return RollingCareProtocolWindow(
            code: code,
            title: title,
            name: "",
            active: false,
            budget: 0.0,
            retries: 0,
            weight: 0.0,
            status: RollingCareProtocolWindowStatus.new
        )
    }
}
