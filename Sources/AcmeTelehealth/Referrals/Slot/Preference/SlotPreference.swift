import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot preference is in its life cycle.
    enum SlotPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A slot preference. Its code is unique within a tenant.
    final class SlotPreference {
        var code: String
        var label: String
        var startsAt: Int
        var name: String
        var retries: Int
        var version: Int
        var status: SlotPreferenceStatus

        init(code: String, label: String, startsAt: Int, name: String, retries: Int, version: Int, status: SlotPreferenceStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.name = name
            self.retries = retries
            self.version = version
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

        func canMoveTo(_ next: SlotPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == SlotPreferenceStatus.ready || next == SlotPreferenceStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SlotPreferenceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("slot preference") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(startsAt) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> SlotPreference {
            return SlotPreference(
                code: code,
                label: label,
                startsAt: startsAt,
                name: name,
                retries: retries,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a slot preference in status idle.
    static func newSlotPreference(_ code: String, label: String) -> SlotPreference {
        return SlotPreference(
            code: code,
            label: label,
            startsAt: 0,
            name: "",
            retries: 0,
            version: 0,
            status: SlotPreferenceStatus.idle
        )
    }
}
