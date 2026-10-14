import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict claim checkpoint is in its life cycle.
    enum StrictClaimCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A strict claim checkpoint as the claim team keeps it.
    final class StrictClaimCheckpoint {
        var code: String
        var title: String
        var floorValue: Double
        var endsAt: Int
        var name: String
        var margin: Double
        var priority: Int
        var locale: String
        var category: String
        var specialty: String
        var status: StrictClaimCheckpointStatus

        init(code: String, title: String, floorValue: Double, endsAt: Int, name: String, margin: Double, priority: Int, locale: String, category: String, specialty: String, status: StrictClaimCheckpointStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.endsAt = endsAt
            self.name = name
            self.margin = margin
            self.priority = priority
            self.locale = locale
            self.category = category
            self.specialty = specialty
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

        func canMoveTo(_ next: StrictClaimCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == StrictClaimCheckpointStatus.draining || next == StrictClaimCheckpointStatus.stopped
            case .ready:
                return next == StrictClaimCheckpointStatus.draining
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

        func moveTo(_ next: StrictClaimCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict claim checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return ((Double(priority) - margin) * 100).rounded() / 100
        }

        func copyValue() -> StrictClaimCheckpoint {
            return StrictClaimCheckpoint(
                code: code,
                title: title,
                floorValue: floorValue,
                endsAt: endsAt,
                name: name,
                margin: margin,
                priority: priority,
                locale: locale,
                category: category,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict claim checkpoint in status idle.
    static func newStrictClaimCheckpoint(_ code: String, title: String) -> StrictClaimCheckpoint {
        return StrictClaimCheckpoint(
            code: code,
            title: title,
            floorValue: 0.0,
            endsAt: 0,
            name: "",
            margin: 0.0,
            priority: 0,
            locale: "",
            category: "",
            specialty: "",
            status: StrictClaimCheckpointStatus.idle
        )
    }
}
