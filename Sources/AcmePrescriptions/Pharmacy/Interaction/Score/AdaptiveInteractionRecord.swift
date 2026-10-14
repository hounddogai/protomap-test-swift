import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive interaction record is in its life cycle.
    enum AdaptiveInteractionRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One adaptive interaction record, with what the planners need to act on it.
    final class AdaptiveInteractionRecord {
        var code: String
        var title: String
        var ceiling: Double
        var cost: Double
        var tags: [String]
        var summary: String
        var facility: String
        var floorValue: Double
        var rate: Double
        var source: String
        var status: AdaptiveInteractionRecordStatus

        init(code: String, title: String, ceiling: Double, cost: Double, tags: [String], summary: String, facility: String, floorValue: Double, rate: Double, source: String, status: AdaptiveInteractionRecordStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.cost = cost
            self.tags = tags
            self.summary = summary
            self.facility = facility
            self.floorValue = floorValue
            self.rate = rate
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveInteractionRecordStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveInteractionRecordStatus.queued || next == AdaptiveInteractionRecordStatus.failed
            case .queued:
                return next == AdaptiveInteractionRecordStatus.running || next == AdaptiveInteractionRecordStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AdaptiveInteractionRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive interaction record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive interaction record") \(code)"
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
            return ((floorValue - rate) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveInteractionRecord {
            return AdaptiveInteractionRecord(
                code: code,
                title: title,
                ceiling: ceiling,
                cost: cost,
                tags: tags,
                summary: summary,
                facility: facility,
                floorValue: floorValue,
                rate: rate,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive interaction record in status new.
    static func newAdaptiveInteractionRecord(_ code: String, title: String) -> AdaptiveInteractionRecord {
        return AdaptiveInteractionRecord(
            code: code,
            title: title,
            ceiling: 0.0,
            cost: 0.0,
            tags: [],
            summary: "",
            facility: "",
            floorValue: 0.0,
            rate: 0.0,
            source: "",
            status: AdaptiveInteractionRecordStatus.new
        )
    }
}
