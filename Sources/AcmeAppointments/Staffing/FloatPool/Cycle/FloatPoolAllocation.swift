import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool allocation is in its life cycle.
    enum FloatPoolAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One float pool allocation, with what the planners need to act on it.
    final class FloatPoolAllocation {
        var code: String
        var title: String
        var sequence: Int
        var ward: String
        var archived: Bool
        var margin: Double
        var tags: [String]
        var priority: Int
        var description: String
        var batchSize: Int
        var status: FloatPoolAllocationStatus

        init(code: String, title: String, sequence: Int, ward: String, archived: Bool, margin: Double, tags: [String], priority: Int, description: String, batchSize: Int, status: FloatPoolAllocationStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.ward = ward
            self.archived = archived
            self.margin = margin
            self.tags = tags
            self.priority = priority
            self.description = description
            self.batchSize = batchSize
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

        func canMoveTo(_ next: FloatPoolAllocationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FloatPoolAllocationStatus.draining || next == FloatPoolAllocationStatus.stopped
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

        func moveTo(_ next: FloatPoolAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("float pool allocation") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return (Double(priority) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolAllocation {
            return FloatPoolAllocation(
                code: code,
                title: title,
                sequence: sequence,
                ward: ward,
                archived: archived,
                margin: margin,
                tags: tags,
                priority: priority,
                description: description,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a float pool allocation in status idle.
    static func newFloatPoolAllocation(_ code: String, title: String) -> FloatPoolAllocation {
        return FloatPoolAllocation(
            code: code,
            title: title,
            sequence: 0,
            ward: "",
            archived: false,
            margin: 0.0,
            tags: [],
            priority: 0,
            description: "",
            batchSize: 0,
            status: FloatPoolAllocationStatus.idle
        )
    }
}
