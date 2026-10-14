import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift variance is in its life cycle.
    enum ShiftVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a shift variance and its current status.
    final class ShiftVariance {
        var code: String
        var title: String
        var reviewer: String
        var diagnosisCode: String
        var ceiling: Double
        var endsAt: Int
        var checksum: String
        var facility: String
        var region: String
        var createdAt: Int
        var status: ShiftVarianceStatus

        init(code: String, title: String, reviewer: String, diagnosisCode: String, ceiling: Double, endsAt: Int, checksum: String, facility: String, region: String, createdAt: Int, status: ShiftVarianceStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.diagnosisCode = diagnosisCode
            self.ceiling = ceiling
            self.endsAt = endsAt
            self.checksum = checksum
            self.facility = facility
            self.region = region
            self.createdAt = createdAt
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

        func canMoveTo(_ next: ShiftVarianceStatus) -> Bool {
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
                return next == ShiftVarianceStatus.done || next == ShiftVarianceStatus.failed
            case .running:
                return next == ShiftVarianceStatus.done
            case .done:
                return next == ShiftVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedExposure() -> Double {
            return (Double(endsAt) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> ShiftVariance {
            return ShiftVariance(
                code: code,
                title: title,
                reviewer: reviewer,
                diagnosisCode: diagnosisCode,
                ceiling: ceiling,
                endsAt: endsAt,
                checksum: checksum,
                facility: facility,
                region: region,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a shift variance in status new.
    static func newShiftVariance(_ code: String, title: String) -> ShiftVariance {
        return ShiftVariance(
            code: code,
            title: title,
            reviewer: "",
            diagnosisCode: "",
            ceiling: 0.0,
            endsAt: 0,
            checksum: "",
            facility: "",
            region: "",
            createdAt: 0,
            status: ShiftVarianceStatus.new
        )
    }
}
