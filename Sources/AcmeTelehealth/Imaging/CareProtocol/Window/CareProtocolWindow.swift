import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol window is in its life cycle.
    enum CareProtocolWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One care protocol window, with what the planners need to act on it.
    final class CareProtocolWindow {
        var code: String
        var label: String
        var margin: Double
        var segment: String
        var maximum: Double
        var weight: Double
        var batchSize: Int
        var attempts: Int
        var notes: String
        var capacity: Int
        var status: CareProtocolWindowStatus

        init(code: String, label: String, margin: Double, segment: String, maximum: Double, weight: Double, batchSize: Int, attempts: Int, notes: String, capacity: Int, status: CareProtocolWindowStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.segment = segment
            self.maximum = maximum
            self.weight = weight
            self.batchSize = batchSize
            self.attempts = attempts
            self.notes = notes
            self.capacity = capacity
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

        func canMoveTo(_ next: CareProtocolWindowStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolWindowStatus.done || next == CareProtocolWindowStatus.failed
            case .queued:
                return next == CareProtocolWindowStatus.done
            case .running:
                return next == CareProtocolWindowStatus.failed
            case .done:
                return next == CareProtocolWindowStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedLoad() -> Double {
            return ((margin + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolWindow {
            return CareProtocolWindow(
                code: code,
                label: label,
                margin: margin,
                segment: segment,
                maximum: maximum,
                weight: weight,
                batchSize: batchSize,
                attempts: attempts,
                notes: notes,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a care protocol window in status new.
    static func newCareProtocolWindow(_ code: String, label: String) -> CareProtocolWindow {
        return CareProtocolWindow(
            code: code,
            label: label,
            margin: 0.0,
            segment: "",
            maximum: 0.0,
            weight: 0.0,
            batchSize: 0,
            attempts: 0,
            notes: "",
            capacity: 0,
            status: CareProtocolWindowStatus.new
        )
    }
}
