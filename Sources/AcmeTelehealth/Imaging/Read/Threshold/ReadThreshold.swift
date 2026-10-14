import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read threshold is in its life cycle.
    enum ReadThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a read threshold and its current status.
    final class ReadThreshold {
        var code: String
        var title: String
        var diagnosisCode: String
        var segment: String
        var capacity: Int
        var cost: Double
        var reviewer: String
        var specialty: String
        var maximum: Double
        var status: ReadThresholdStatus

        init(code: String, title: String, diagnosisCode: String, segment: String, capacity: Int, cost: Double, reviewer: String, specialty: String, maximum: Double, status: ReadThresholdStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.segment = segment
            self.capacity = capacity
            self.cost = cost
            self.reviewer = reviewer
            self.specialty = specialty
            self.maximum = maximum
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

        func canMoveTo(_ next: ReadThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == ReadThresholdStatus.done || next == ReadThresholdStatus.failed
            case .queued:
                return next == ReadThresholdStatus.running
            case .running:
                return next == ReadThresholdStatus.failed
            case .done:
                return next == ReadThresholdStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("read threshold") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(capacity) - cost) * 100).rounded() / 100
        }

        func copyValue() -> ReadThreshold {
            return ReadThreshold(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                segment: segment,
                capacity: capacity,
                cost: cost,
                reviewer: reviewer,
                specialty: specialty,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a read threshold in status new.
    static func newReadThreshold(_ code: String, title: String) -> ReadThreshold {
        return ReadThreshold(
            code: code,
            title: title,
            diagnosisCode: "",
            segment: "",
            capacity: 0,
            cost: 0.0,
            reviewer: "",
            specialty: "",
            maximum: 0.0,
            status: ReadThresholdStatus.new
        )
    }
}
