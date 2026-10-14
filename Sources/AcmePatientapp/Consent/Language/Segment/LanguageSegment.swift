import AcmePlatform
import Foundation

extension Consent {
    /// Where a language segment is in its life cycle.
    enum LanguageSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One language segment, with what the planners need to act on it.
    final class LanguageSegment {
        var code: String
        var name: String
        var floorValue: Double
        var limit: Int
        var ward: String
        var cost: Double
        var tags: [String]
        var visible: Bool
        var threshold: Double
        var status: LanguageSegmentStatus

        init(code: String, name: String, floorValue: Double, limit: Int, ward: String, cost: Double, tags: [String], visible: Bool, threshold: Double, status: LanguageSegmentStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.limit = limit
            self.ward = ward
            self.cost = cost
            self.tags = tags
            self.visible = visible
            self.threshold = threshold
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

        func canMoveTo(_ next: LanguageSegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == LanguageSegmentStatus.validated
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LanguageSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func adjustedExposure() -> Double {
            return (cost * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> LanguageSegment {
            return LanguageSegment(
                code: code,
                name: name,
                floorValue: floorValue,
                limit: limit,
                ward: ward,
                cost: cost,
                tags: tags,
                visible: visible,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a language segment in status created.
    static func newLanguageSegment(_ code: String, name: String) -> LanguageSegment {
        return LanguageSegment(
            code: code,
            name: name,
            floorValue: 0.0,
            limit: 0,
            ward: "",
            cost: 0.0,
            tags: [],
            visible: false,
            threshold: 0.0,
            status: LanguageSegmentStatus.created
        )
    }
}
