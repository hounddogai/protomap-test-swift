import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary bed board metric is in its life cycle.
    enum PrimaryBedBoardMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One primary bed board metric, with what the planners need to act on it.
    final class PrimaryBedBoardMetric {
        var code: String
        var name: String
        var maximum: Double
        var capacity: Int
        var updatedAt: Int
        var archived: Bool
        var category: String
        var windowDays: Int
        var createdAt: Int
        var status: PrimaryBedBoardMetricStatus

        init(code: String, name: String, maximum: Double, capacity: Int, updatedAt: Int, archived: Bool, category: String, windowDays: Int, createdAt: Int, status: PrimaryBedBoardMetricStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.capacity = capacity
            self.updatedAt = updatedAt
            self.archived = archived
            self.category = category
            self.windowDays = windowDays
            self.createdAt = createdAt
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

        func canMoveTo(_ next: PrimaryBedBoardMetricStatus) -> Bool {
            switch status {
            case .idle:
                return next == PrimaryBedBoardMetricStatus.warming || next == PrimaryBedBoardMetricStatus.ready
            case .warming:
                return next == PrimaryBedBoardMetricStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryBedBoardMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary bed board metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedLoad() -> Double {
            return ((Double(windowDays) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryBedBoardMetric {
            return PrimaryBedBoardMetric(
                code: code,
                name: name,
                maximum: maximum,
                capacity: capacity,
                updatedAt: updatedAt,
                archived: archived,
                category: category,
                windowDays: windowDays,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a primary bed board metric in status idle.
    static func newPrimaryBedBoardMetric(_ code: String, name: String) -> PrimaryBedBoardMetric {
        return PrimaryBedBoardMetric(
            code: code,
            name: name,
            maximum: 0.0,
            capacity: 0,
            updatedAt: 0,
            archived: false,
            category: "",
            windowDays: 0,
            createdAt: 0,
            status: PrimaryBedBoardMetricStatus.idle
        )
    }
}
