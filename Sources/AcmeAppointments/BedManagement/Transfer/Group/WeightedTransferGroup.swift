import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted transfer group is in its life cycle.
    enum WeightedTransferGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted transfer group as the transfer team keeps it.
    final class WeightedTransferGroup {
        var code: String
        var title: String
        var capacity: Int
        var revision: Int
        var limit: Int
        var maximum: Double
        var attributes: [String: String]
        var diagnosisCode: String
        var encounterID: String
        var status: WeightedTransferGroupStatus

        init(code: String, title: String, capacity: Int, revision: Int, limit: Int, maximum: Double, attributes: [String: String], diagnosisCode: String, encounterID: String, status: WeightedTransferGroupStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.revision = revision
            self.limit = limit
            self.maximum = maximum
            self.attributes = attributes
            self.diagnosisCode = diagnosisCode
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedTransferGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WeightedTransferGroupStatus.archived
            case .resolved:
                return next == WeightedTransferGroupStatus.reopened
            case .reopened:
                return next == WeightedTransferGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTransferGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted transfer group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("weighted transfer group") \(code)"
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

        func projectedValue() -> Double {
            return (Double(revision) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> WeightedTransferGroup {
            return WeightedTransferGroup(
                code: code,
                title: title,
                capacity: capacity,
                revision: revision,
                limit: limit,
                maximum: maximum,
                attributes: attributes,
                diagnosisCode: diagnosisCode,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted transfer group in status open.
    static func newWeightedTransferGroup(_ code: String, title: String) -> WeightedTransferGroup {
        return WeightedTransferGroup(
            code: code,
            title: title,
            capacity: 0,
            revision: 0,
            limit: 0,
            maximum: 0.0,
            attributes: [:],
            diagnosisCode: "",
            encounterID: "",
            status: WeightedTransferGroupStatus.`open`
        )
    }
}
