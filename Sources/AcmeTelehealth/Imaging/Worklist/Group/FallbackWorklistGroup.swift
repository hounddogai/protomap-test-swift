import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback worklist group is in its life cycle.
    enum FallbackWorklistGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One fallback worklist group, with what the planners need to act on it.
    final class FallbackWorklistGroup {
        var code: String
        var name: String
        var unit: String
        var sequence: Int
        var channel: String
        var active: Bool
        var maximum: Double
        var title: String
        var notes: String
        var payer: String
        var pinned: Bool
        var status: FallbackWorklistGroupStatus

        init(code: String, name: String, unit: String, sequence: Int, channel: String, active: Bool, maximum: Double, title: String, notes: String, payer: String, pinned: Bool, status: FallbackWorklistGroupStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.sequence = sequence
            self.channel = channel
            self.active = active
            self.maximum = maximum
            self.title = title
            self.notes = notes
            self.payer = payer
            self.pinned = pinned
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

        func canMoveTo(_ next: FallbackWorklistGroupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FallbackWorklistGroupStatus.done || next == FallbackWorklistGroupStatus.failed
            case .running:
                return next == FallbackWorklistGroupStatus.done || next == FallbackWorklistGroupStatus.failed
            case .done:
                return next == FallbackWorklistGroupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackWorklistGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback worklist group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return ((maximum + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackWorklistGroup {
            return FallbackWorklistGroup(
                code: code,
                name: name,
                unit: unit,
                sequence: sequence,
                channel: channel,
                active: active,
                maximum: maximum,
                title: title,
                notes: notes,
                payer: payer,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a fallback worklist group in status new.
    static func newFallbackWorklistGroup(_ code: String, name: String) -> FallbackWorklistGroup {
        return FallbackWorklistGroup(
            code: code,
            name: name,
            unit: "",
            sequence: 0,
            channel: "",
            active: false,
            maximum: 0.0,
            title: "",
            notes: "",
            payer: "",
            pinned: false,
            status: FallbackWorklistGroupStatus.new
        )
    }
}
