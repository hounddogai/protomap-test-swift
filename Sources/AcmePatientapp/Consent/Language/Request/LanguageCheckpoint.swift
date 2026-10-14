import AcmePlatform
import Foundation

extension Consent {
    /// Where a language checkpoint is in its life cycle.
    enum LanguageCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One language checkpoint, with what the planners need to act on it.
    final class LanguageCheckpoint {
        var code: String
        var name: String
        var contactEmail: String
        var channel: String
        var cost: Double
        var dosageMg: Double
        var refills: Int
        var country: String
        var capacity: Int
        var status: LanguageCheckpointStatus

        init(code: String, name: String, contactEmail: String, channel: String, cost: Double, dosageMg: Double, refills: Int, country: String, capacity: Int, status: LanguageCheckpointStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.channel = channel
            self.cost = cost
            self.dosageMg = dosageMg
            self.refills = refills
            self.country = country
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LanguageCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == LanguageCheckpointStatus.completed || next == LanguageCheckpointStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LanguageCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("language checkpoint") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((dosageMg - cost) * 100).rounded() / 100
        }

        func copyValue() -> LanguageCheckpoint {
            return LanguageCheckpoint(
                code: code,
                name: name,
                contactEmail: contactEmail,
                channel: channel,
                cost: cost,
                dosageMg: dosageMg,
                refills: refills,
                country: country,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a language checkpoint in status planned.
    static func newLanguageCheckpoint(_ code: String, name: String) -> LanguageCheckpoint {
        return LanguageCheckpoint(
            code: code,
            name: name,
            contactEmail: "",
            channel: "",
            cost: 0.0,
            dosageMg: 0.0,
            refills: 0,
            country: "",
            capacity: 0,
            status: LanguageCheckpointStatus.planned
        )
    }
}
