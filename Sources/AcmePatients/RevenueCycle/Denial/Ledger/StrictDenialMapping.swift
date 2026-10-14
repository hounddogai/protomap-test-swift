import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict denial mapping is in its life cycle.
    enum StrictDenialMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict denial mapping. Its code is unique within a tenant.
    final class StrictDenialMapping {
        var code: String
        var name: String
        var summary: String
        var discount: Double
        var tags: [String]
        var version: Int
        var status: StrictDenialMappingStatus

        init(code: String, name: String, summary: String, discount: Double, tags: [String], version: Int, status: StrictDenialMappingStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.discount = discount
            self.tags = tags
            self.version = version
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

        func canMoveTo(_ next: StrictDenialMappingStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == StrictDenialMappingStatus.completed || next == StrictDenialMappingStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == StrictDenialMappingStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictDenialMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict denial mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return (Double(version) * discount * 100).rounded() / 100
        }

        func copyValue() -> StrictDenialMapping {
            return StrictDenialMapping(
                code: code,
                name: name,
                summary: summary,
                discount: discount,
                tags: tags,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict denial mapping in status planned.
    static func newStrictDenialMapping(_ code: String, name: String) -> StrictDenialMapping {
        return StrictDenialMapping(
            code: code,
            name: name,
            summary: "",
            discount: 0.0,
            tags: [],
            version: 0,
            status: StrictDenialMappingStatus.planned
        )
    }
}
