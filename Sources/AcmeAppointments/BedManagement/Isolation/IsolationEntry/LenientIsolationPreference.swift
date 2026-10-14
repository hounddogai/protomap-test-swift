import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient isolation preference is in its life cycle.
    enum LenientIsolationPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One lenient isolation preference, with what the planners need to act on it.
    final class LenientIsolationPreference {
        var code: String
        var title: String
        var description: String
        var allergy: String
        var limit: Int
        var priority: Int
        var durationMinutes: Int
        var refills: Int
        var capacity: Int
        var copay: Double
        var externalRef: String
        var status: LenientIsolationPreferenceStatus

        init(code: String, title: String, description: String, allergy: String, limit: Int, priority: Int, durationMinutes: Int, refills: Int, capacity: Int, copay: Double, externalRef: String, status: LenientIsolationPreferenceStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.allergy = allergy
            self.limit = limit
            self.priority = priority
            self.durationMinutes = durationMinutes
            self.refills = refills
            self.capacity = capacity
            self.copay = copay
            self.externalRef = externalRef
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

        func canMoveTo(_ next: LenientIsolationPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientIsolationPreferenceStatus.ready
            case .warming:
                return next == LenientIsolationPreferenceStatus.ready || next == LenientIsolationPreferenceStatus.stopped
            case .ready:
                return next == LenientIsolationPreferenceStatus.draining || next == LenientIsolationPreferenceStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LenientIsolationPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient isolation preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedValue() -> Double {
            return ((Double(limit) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> LenientIsolationPreference {
            return LenientIsolationPreference(
                code: code,
                title: title,
                description: description,
                allergy: allergy,
                limit: limit,
                priority: priority,
                durationMinutes: durationMinutes,
                refills: refills,
                capacity: capacity,
                copay: copay,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient isolation preference in status idle.
    static func newLenientIsolationPreference(_ code: String, title: String) -> LenientIsolationPreference {
        return LenientIsolationPreference(
            code: code,
            title: title,
            description: "",
            allergy: "",
            limit: 0,
            priority: 0,
            durationMinutes: 0,
            refills: 0,
            capacity: 0,
            copay: 0.0,
            externalRef: "",
            status: LenientIsolationPreferenceStatus.idle
        )
    }
}
