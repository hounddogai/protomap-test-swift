import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement segment is in its life cycle.
    enum StatementSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One statement segment, with what the planners need to act on it.
    final class StatementSegment {
        var code: String
        var title: String
        var ward: String
        var refills: Int
        var durationMinutes: Int
        var tags: [String]
        var minimum: Double
        var encounterID: String
        var floorValue: Double
        var status: StatementSegmentStatus

        init(code: String, title: String, ward: String, refills: Int, durationMinutes: Int, tags: [String], minimum: Double, encounterID: String, floorValue: Double, status: StatementSegmentStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.refills = refills
            self.durationMinutes = durationMinutes
            self.tags = tags
            self.minimum = minimum
            self.encounterID = encounterID
            self.floorValue = floorValue
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

        func canMoveTo(_ next: StatementSegmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
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

        func moveTo(_ next: StatementSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("statement segment") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return ((Double(refills) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StatementSegment {
            return StatementSegment(
                code: code,
                title: title,
                ward: ward,
                refills: refills,
                durationMinutes: durationMinutes,
                tags: tags,
                minimum: minimum,
                encounterID: encounterID,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a statement segment in status idle.
    static func newStatementSegment(_ code: String, title: String) -> StatementSegment {
        return StatementSegment(
            code: code,
            title: title,
            ward: "",
            refills: 0,
            durationMinutes: 0,
            tags: [],
            minimum: 0.0,
            encounterID: "",
            floorValue: 0.0,
            status: StatementSegmentStatus.idle
        )
    }
}
