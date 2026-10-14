import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict specimen adjustment is in its life cycle.
    enum StrictSpecimenAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One strict specimen adjustment, with what the planners need to act on it.
    final class StrictSpecimenAdjustment {
        var code: String
        var name: String
        var attributes: [String: String]
        var contactEmail: String
        var startsAt: Int
        var status: StrictSpecimenAdjustmentStatus

        init(code: String, name: String, attributes: [String: String], contactEmail: String, startsAt: Int, status: StrictSpecimenAdjustmentStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.contactEmail = contactEmail
            self.startsAt = startsAt
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

        func canMoveTo(_ next: StrictSpecimenAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictSpecimenAdjustmentStatus.running || next == StrictSpecimenAdjustmentStatus.done
            case .queued:
                return next == StrictSpecimenAdjustmentStatus.failed
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: StrictSpecimenAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict specimen adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
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
            return Double(startsAt)
        }

        func copyValue() -> StrictSpecimenAdjustment {
            return StrictSpecimenAdjustment(
                code: code,
                name: name,
                attributes: attributes,
                contactEmail: contactEmail,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict specimen adjustment in status new.
    static func newStrictSpecimenAdjustment(_ code: String, name: String) -> StrictSpecimenAdjustment {
        return StrictSpecimenAdjustment(
            code: code,
            name: name,
            attributes: [:],
            contactEmail: "",
            startsAt: 0,
            status: StrictSpecimenAdjustmentStatus.new
        )
    }
}
