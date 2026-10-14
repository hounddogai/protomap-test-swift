import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled isolation segment is in its life cycle.
    enum ScheduledIsolationSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled isolation segment. Its code is unique within a tenant.
    final class ScheduledIsolationSegment {
        var code: String
        var name: String
        var notes: String
        var attributes: [String: String]
        var updatedAt: Int
        var limit: Int
        var weight: Double
        var status: ScheduledIsolationSegmentStatus

        init(code: String, name: String, notes: String, attributes: [String: String], updatedAt: Int, limit: Int, weight: Double, status: ScheduledIsolationSegmentStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.attributes = attributes
            self.updatedAt = updatedAt
            self.limit = limit
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledIsolationSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ScheduledIsolationSegmentStatus.suspended || next == ScheduledIsolationSegmentStatus.closed
            case .suspended:
                return next == ScheduledIsolationSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledIsolationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled isolation segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("scheduled isolation segment") \(code)"
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

        func adjustedValue() -> Double {
            return ((Double(updatedAt) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledIsolationSegment {
            return ScheduledIsolationSegment(
                code: code,
                name: name,
                notes: notes,
                attributes: attributes,
                updatedAt: updatedAt,
                limit: limit,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled isolation segment in status draft.
    static func newScheduledIsolationSegment(_ code: String, name: String) -> ScheduledIsolationSegment {
        return ScheduledIsolationSegment(
            code: code,
            name: name,
            notes: "",
            attributes: [:],
            updatedAt: 0,
            limit: 0,
            weight: 0.0,
            status: ScheduledIsolationSegmentStatus.draft
        )
    }
}
