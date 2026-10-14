import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy isolation profile is in its life cycle.
    enum LegacyIsolationProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One legacy isolation profile, with what the planners need to act on it.
    final class LegacyIsolationProfile {
        var code: String
        var title: String
        var facility: String
        var description: String
        var copay: Double
        var status: LegacyIsolationProfileStatus

        init(code: String, title: String, facility: String, description: String, copay: Double, status: LegacyIsolationProfileStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.description = description
            self.copay = copay
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

        func canMoveTo(_ next: LegacyIsolationProfileStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LegacyIsolationProfileStatus.draining || next == LegacyIsolationProfileStatus.stopped
            case .ready:
                return next == LegacyIsolationProfileStatus.stopped
            case .draining:
                return next == LegacyIsolationProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyIsolationProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy isolation profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> LegacyIsolationProfile {
            return LegacyIsolationProfile(
                code: code,
                title: title,
                facility: facility,
                description: description,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy isolation profile in status idle.
    static func newLegacyIsolationProfile(_ code: String, title: String) -> LegacyIsolationProfile {
        return LegacyIsolationProfile(
            code: code,
            title: title,
            facility: "",
            description: "",
            copay: 0.0,
            status: LegacyIsolationProfileStatus.idle
        )
    }
}
