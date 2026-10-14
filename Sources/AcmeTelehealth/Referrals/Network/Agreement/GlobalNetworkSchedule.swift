import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global network schedule is in its life cycle.
    enum GlobalNetworkScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a global network schedule and its current status.
    final class GlobalNetworkSchedule {
        var code: String
        var name: String
        var durationMinutes: Int
        var attributes: [String: String]
        var contactEmail: String
        var externalRef: String
        var region: String
        var pinned: Bool
        var status: GlobalNetworkScheduleStatus

        init(code: String, name: String, durationMinutes: Int, attributes: [String: String], contactEmail: String, externalRef: String, region: String, pinned: Bool, status: GlobalNetworkScheduleStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.attributes = attributes
            self.contactEmail = contactEmail
            self.externalRef = externalRef
            self.region = region
            self.pinned = pinned
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

        func canMoveTo(_ next: GlobalNetworkScheduleStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalNetworkScheduleStatus.running || next == GlobalNetworkScheduleStatus.done
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: GlobalNetworkScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global network schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> GlobalNetworkSchedule {
            return GlobalNetworkSchedule(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                attributes: attributes,
                contactEmail: contactEmail,
                externalRef: externalRef,
                region: region,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global network schedule in status new.
    static func newGlobalNetworkSchedule(_ code: String, name: String) -> GlobalNetworkSchedule {
        return GlobalNetworkSchedule(
            code: code,
            name: name,
            durationMinutes: 0,
            attributes: [:],
            contactEmail: "",
            externalRef: "",
            region: "",
            pinned: false,
            status: GlobalNetworkScheduleStatus.new
        )
    }
}
