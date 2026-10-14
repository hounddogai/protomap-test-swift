import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered order set cycle is in its life cycle.
    enum TieredOrderSetCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered order set cycle. Its code is unique within a tenant.
    final class TieredOrderSetCycle {
        var code: String
        var label: String
        var version: Int
        var attributes: [String: String]
        var archived: Bool
        var category: String
        var limit: Int
        var visitMinutes: Int
        var status: TieredOrderSetCycleStatus

        init(code: String, label: String, version: Int, attributes: [String: String], archived: Bool, category: String, limit: Int, visitMinutes: Int, status: TieredOrderSetCycleStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.attributes = attributes
            self.archived = archived
            self.category = category
            self.limit = limit
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: TieredOrderSetCycleStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredOrderSetCycleStatus.completed || next == TieredOrderSetCycleStatus.cancelled
            case .scheduled:
                return next == TieredOrderSetCycleStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredOrderSetCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered order set cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("tiered order set cycle") \(code)"
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

        func projectedVolume() -> Double {
            return (Double(version) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> TieredOrderSetCycle {
            return TieredOrderSetCycle(
                code: code,
                label: label,
                version: version,
                attributes: attributes,
                archived: archived,
                category: category,
                limit: limit,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered order set cycle in status planned.
    static func newTieredOrderSetCycle(_ code: String, label: String) -> TieredOrderSetCycle {
        return TieredOrderSetCycle(
            code: code,
            label: label,
            version: 0,
            attributes: [:],
            archived: false,
            category: "",
            limit: 0,
            visitMinutes: 0,
            status: TieredOrderSetCycleStatus.planned
        )
    }
}
