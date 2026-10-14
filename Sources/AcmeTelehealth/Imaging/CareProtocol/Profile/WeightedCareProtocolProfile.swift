import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted care protocol profile is in its life cycle.
    enum WeightedCareProtocolProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted care protocol profile. Its code is unique within a tenant.
    final class WeightedCareProtocolProfile {
        var code: String
        var title: String
        var unit: String
        var timezone: String
        var durationMinutes: Int
        var sequence: Int
        var specialty: String
        var procedureCode: String
        var status: WeightedCareProtocolProfileStatus

        init(code: String, title: String, unit: String, timezone: String, durationMinutes: Int, sequence: Int, specialty: String, procedureCode: String, status: WeightedCareProtocolProfileStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.timezone = timezone
            self.durationMinutes = durationMinutes
            self.sequence = sequence
            self.specialty = specialty
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: WeightedCareProtocolProfileStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedCareProtocolProfileStatus.queued
            case .queued:
                return next == WeightedCareProtocolProfileStatus.done || next == WeightedCareProtocolProfileStatus.failed
            case .running:
                return next == WeightedCareProtocolProfileStatus.failed
            case .done:
                return next == WeightedCareProtocolProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedCareProtocolProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted care protocol profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return (Double(sequence) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCareProtocolProfile {
            return WeightedCareProtocolProfile(
                code: code,
                title: title,
                unit: unit,
                timezone: timezone,
                durationMinutes: durationMinutes,
                sequence: sequence,
                specialty: specialty,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted care protocol profile in status new.
    static func newWeightedCareProtocolProfile(_ code: String, title: String) -> WeightedCareProtocolProfile {
        return WeightedCareProtocolProfile(
            code: code,
            title: title,
            unit: "",
            timezone: "",
            durationMinutes: 0,
            sequence: 0,
            specialty: "",
            procedureCode: "",
            status: WeightedCareProtocolProfileStatus.new
        )
    }
}
