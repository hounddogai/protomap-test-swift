import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global denial milestone is in its life cycle.
    enum GlobalDenialMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One global denial milestone, with what the planners need to act on it.
    final class GlobalDenialMilestone {
        var code: String
        var name: String
        var maximum: Double
        var encounterID: String
        var phone: String
        var locale: String
        var status: GlobalDenialMilestoneStatus

        init(code: String, name: String, maximum: Double, encounterID: String, phone: String, locale: String, status: GlobalDenialMilestoneStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.encounterID = encounterID
            self.phone = phone
            self.locale = locale
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

        func canMoveTo(_ next: GlobalDenialMilestoneStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == GlobalDenialMilestoneStatus.running || next == GlobalDenialMilestoneStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == GlobalDenialMilestoneStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalDenialMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global denial milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> GlobalDenialMilestone {
            return GlobalDenialMilestone(
                code: code,
                name: name,
                maximum: maximum,
                encounterID: encounterID,
                phone: phone,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global denial milestone in status new.
    static func newGlobalDenialMilestone(_ code: String, name: String) -> GlobalDenialMilestone {
        return GlobalDenialMilestone(
            code: code,
            name: name,
            maximum: 0.0,
            encounterID: "",
            phone: "",
            locale: "",
            status: GlobalDenialMilestoneStatus.new
        )
    }
}
