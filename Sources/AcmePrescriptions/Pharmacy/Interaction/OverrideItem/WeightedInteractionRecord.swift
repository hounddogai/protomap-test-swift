import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted interaction record is in its life cycle.
    enum WeightedInteractionRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One weighted interaction record, with what the planners need to act on it.
    final class WeightedInteractionRecord {
        var code: String
        var title: String
        var ratio: Double
        var attributes: [String: String]
        var ownerID: String
        var startsAt: Int
        var status: WeightedInteractionRecordStatus

        init(code: String, title: String, ratio: Double, attributes: [String: String], ownerID: String, startsAt: Int, status: WeightedInteractionRecordStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.attributes = attributes
            self.ownerID = ownerID
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedInteractionRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == WeightedInteractionRecordStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: WeightedInteractionRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted interaction record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func weightedExposure() -> Double {
            return ((Double(startsAt) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> WeightedInteractionRecord {
            return WeightedInteractionRecord(
                code: code,
                title: title,
                ratio: ratio,
                attributes: attributes,
                ownerID: ownerID,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted interaction record in status proposed.
    static func newWeightedInteractionRecord(_ code: String, title: String) -> WeightedInteractionRecord {
        return WeightedInteractionRecord(
            code: code,
            title: title,
            ratio: 0.0,
            attributes: [:],
            ownerID: "",
            startsAt: 0,
            status: WeightedInteractionRecordStatus.proposed
        )
    }
}
