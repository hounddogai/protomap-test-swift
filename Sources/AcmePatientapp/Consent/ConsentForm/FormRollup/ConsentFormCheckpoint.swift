import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form checkpoint is in its life cycle.
    enum ConsentFormCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A consent form checkpoint as the consent form team keeps it.
    final class ConsentFormCheckpoint {
        var code: String
        var title: String
        var rate: Double
        var ownerID: String
        var tags: [String]
        var unit: String
        var endsAt: Int
        var status: ConsentFormCheckpointStatus

        init(code: String, title: String, rate: Double, ownerID: String, tags: [String], unit: String, endsAt: Int, status: ConsentFormCheckpointStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.ownerID = ownerID
            self.tags = tags
            self.unit = unit
            self.endsAt = endsAt
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

        func canMoveTo(_ next: ConsentFormCheckpointStatus) -> Bool {
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
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ConsentFormCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return ((Double(endsAt) + rate) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormCheckpoint {
            return ConsentFormCheckpoint(
                code: code,
                title: title,
                rate: rate,
                ownerID: ownerID,
                tags: tags,
                unit: unit,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a consent form checkpoint in status planned.
    static func newConsentFormCheckpoint(_ code: String, title: String) -> ConsentFormCheckpoint {
        return ConsentFormCheckpoint(
            code: code,
            title: title,
            rate: 0.0,
            ownerID: "",
            tags: [],
            unit: "",
            endsAt: 0,
            status: ConsentFormCheckpointStatus.planned
        )
    }
}
