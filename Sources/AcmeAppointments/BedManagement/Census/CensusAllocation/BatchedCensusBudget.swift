import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched census budget is in its life cycle.
    enum BatchedCensusBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a batched census budget and its current status.
    final class BatchedCensusBudget {
        var code: String
        var label: String
        var startsAt: Int
        var sequence: Int
        var refills: Int
        var updatedAt: Int
        var diagnosisCode: String
        var expiresAt: Int
        var rate: Double
        var timezone: String
        var source: String
        var status: BatchedCensusBudgetStatus

        init(code: String, label: String, startsAt: Int, sequence: Int, refills: Int, updatedAt: Int, diagnosisCode: String, expiresAt: Int, rate: Double, timezone: String, source: String, status: BatchedCensusBudgetStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.sequence = sequence
            self.refills = refills
            self.updatedAt = updatedAt
            self.diagnosisCode = diagnosisCode
            self.expiresAt = expiresAt
            self.rate = rate
            self.timezone = timezone
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

        func canMoveTo(_ next: BatchedCensusBudgetStatus) -> Bool {
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
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BatchedCensusBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCensusBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched census budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("batched census budget") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(sequence) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCensusBudget {
            return BatchedCensusBudget(
                code: code,
                label: label,
                startsAt: startsAt,
                sequence: sequence,
                refills: refills,
                updatedAt: updatedAt,
                diagnosisCode: diagnosisCode,
                expiresAt: expiresAt,
                rate: rate,
                timezone: timezone,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched census budget in status new.
    static func newBatchedCensusBudget(_ code: String, label: String) -> BatchedCensusBudget {
        return BatchedCensusBudget(
            code: code,
            label: label,
            startsAt: 0,
            sequence: 0,
            refills: 0,
            updatedAt: 0,
            diagnosisCode: "",
            expiresAt: 0,
            rate: 0.0,
            timezone: "",
            source: "",
            status: BatchedCensusBudgetStatus.new
        )
    }
}
