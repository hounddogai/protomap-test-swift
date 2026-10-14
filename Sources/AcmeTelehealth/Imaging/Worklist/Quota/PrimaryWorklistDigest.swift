import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary worklist digest is in its life cycle.
    enum PrimaryWorklistDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One primary worklist digest, with what the planners need to act on it.
    final class PrimaryWorklistDigest {
        var code: String
        var title: String
        var floorValue: Double
        var pinned: Bool
        var durationMinutes: Int
        var attributes: [String: String]
        var sequence: Int
        var status: PrimaryWorklistDigestStatus

        init(code: String, title: String, floorValue: Double, pinned: Bool, durationMinutes: Int, attributes: [String: String], sequence: Int, status: PrimaryWorklistDigestStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.pinned = pinned
            self.durationMinutes = durationMinutes
            self.attributes = attributes
            self.sequence = sequence
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

        func canMoveTo(_ next: PrimaryWorklistDigestStatus) -> Bool {
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
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
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

        func moveTo(_ next: PrimaryWorklistDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary worklist digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
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

        func effectiveVolume() -> Double {
            return ((Double(sequence) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryWorklistDigest {
            return PrimaryWorklistDigest(
                code: code,
                title: title,
                floorValue: floorValue,
                pinned: pinned,
                durationMinutes: durationMinutes,
                attributes: attributes,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary worklist digest in status planned.
    static func newPrimaryWorklistDigest(_ code: String, title: String) -> PrimaryWorklistDigest {
        return PrimaryWorklistDigest(
            code: code,
            title: title,
            floorValue: 0.0,
            pinned: false,
            durationMinutes: 0,
            attributes: [:],
            sequence: 0,
            status: PrimaryWorklistDigestStatus.planned
        )
    }
}
