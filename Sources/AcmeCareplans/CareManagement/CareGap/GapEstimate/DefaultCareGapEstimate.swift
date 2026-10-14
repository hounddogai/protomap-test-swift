import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default care gap estimate is in its life cycle.
    enum DefaultCareGapEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default care gap estimate. Its code is unique within a tenant.
    final class DefaultCareGapEstimate {
        var code: String
        var title: String
        var attempts: Int
        var procedureCode: String
        var sequence: Int
        var quantity: Int
        var graceDays: Int
        var capacity: Int
        var clinicianID: String
        var status: DefaultCareGapEstimateStatus

        init(code: String, title: String, attempts: Int, procedureCode: String, sequence: Int, quantity: Int, graceDays: Int, capacity: Int, clinicianID: String, status: DefaultCareGapEstimateStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.procedureCode = procedureCode
            self.sequence = sequence
            self.quantity = quantity
            self.graceDays = graceDays
            self.capacity = capacity
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: DefaultCareGapEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultCareGapEstimateStatus.queued || next == DefaultCareGapEstimateStatus.done
            case .queued:
                return next == DefaultCareGapEstimateStatus.running || next == DefaultCareGapEstimateStatus.failed
            case .running:
                return next == DefaultCareGapEstimateStatus.failed
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

        func moveTo(_ next: DefaultCareGapEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care gap estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default care gap estimate") \(code)"
        }

        func adjustedVolume() -> Double {
            return (Double(graceDays) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCareGapEstimate {
            return DefaultCareGapEstimate(
                code: code,
                title: title,
                attempts: attempts,
                procedureCode: procedureCode,
                sequence: sequence,
                quantity: quantity,
                graceDays: graceDays,
                capacity: capacity,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default care gap estimate in status new.
    static func newDefaultCareGapEstimate(_ code: String, title: String) -> DefaultCareGapEstimate {
        return DefaultCareGapEstimate(
            code: code,
            title: title,
            attempts: 0,
            procedureCode: "",
            sequence: 0,
            quantity: 0,
            graceDays: 0,
            capacity: 0,
            clinicianID: "",
            status: DefaultCareGapEstimateStatus.new
        )
    }
}
