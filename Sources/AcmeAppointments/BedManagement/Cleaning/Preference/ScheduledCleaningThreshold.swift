import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled cleaning threshold is in its life cycle.
    enum ScheduledCleaningThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a scheduled cleaning threshold and its current status.
    final class ScheduledCleaningThreshold {
        var code: String
        var name: String
        var approved: Bool
        var visible: Bool
        var segment: String
        var country: String
        var locale: String
        var source: String
        var score: Double
        var status: ScheduledCleaningThresholdStatus

        init(code: String, name: String, approved: Bool, visible: Bool, segment: String, country: String, locale: String, source: String, score: Double, status: ScheduledCleaningThresholdStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.visible = visible
            self.segment = segment
            self.country = country
            self.locale = locale
            self.source = source
            self.score = score
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

        func canMoveTo(_ next: ScheduledCleaningThresholdStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ScheduledCleaningThresholdStatus.ready || next == ScheduledCleaningThresholdStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ScheduledCleaningThresholdStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCleaningThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled cleaning threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ScheduledCleaningThreshold {
            return ScheduledCleaningThreshold(
                code: code,
                name: name,
                approved: approved,
                visible: visible,
                segment: segment,
                country: country,
                locale: locale,
                source: source,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled cleaning threshold in status idle.
    static func newScheduledCleaningThreshold(_ code: String, name: String) -> ScheduledCleaningThreshold {
        return ScheduledCleaningThreshold(
            code: code,
            name: name,
            approved: false,
            visible: false,
            segment: "",
            country: "",
            locale: "",
            source: "",
            score: 0.0,
            status: ScheduledCleaningThresholdStatus.idle
        )
    }
}
