import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap checkpoint is in its life cycle.
    enum CareGapCheckpointStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a care gap checkpoint and its current status.
    final class CareGapCheckpoint {
        var code: String
        var name: String
        var discount: Double
        var priority: Int
        var category: String
        var active: Bool
        var ownerID: String
        var endsAt: Int
        var tags: [String]
        var status: CareGapCheckpointStatus

        init(code: String, name: String, discount: Double, priority: Int, category: String, active: Bool, ownerID: String, endsAt: Int, tags: [String], status: CareGapCheckpointStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.priority = priority
            self.category = category
            self.active = active
            self.ownerID = ownerID
            self.endsAt = endsAt
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapCheckpointStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CareGapCheckpointStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CareGapCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return ((discount + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapCheckpoint {
            return CareGapCheckpoint(
                code: code,
                name: name,
                discount: discount,
                priority: priority,
                category: category,
                active: active,
                ownerID: ownerID,
                endsAt: endsAt,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a care gap checkpoint in status created.
    static func newCareGapCheckpoint(_ code: String, name: String) -> CareGapCheckpoint {
        return CareGapCheckpoint(
            code: code,
            name: name,
            discount: 0.0,
            priority: 0,
            category: "",
            active: false,
            ownerID: "",
            endsAt: 0,
            tags: [],
            status: CareGapCheckpointStatus.created
        )
    }
}
