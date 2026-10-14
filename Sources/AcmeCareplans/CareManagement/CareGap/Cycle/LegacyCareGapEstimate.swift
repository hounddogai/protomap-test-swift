import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy care gap estimate is in its life cycle.
    enum LegacyCareGapEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a legacy care gap estimate and its current status.
    final class LegacyCareGapEstimate {
        var code: String
        var name: String
        var clinicianID: String
        var visitMinutes: Int
        var encounterID: String
        var facility: String
        var startsAt: Int
        var durationMinutes: Int
        var ratio: Double
        var status: LegacyCareGapEstimateStatus

        init(code: String, name: String, clinicianID: String, visitMinutes: Int, encounterID: String, facility: String, startsAt: Int, durationMinutes: Int, ratio: Double, status: LegacyCareGapEstimateStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.visitMinutes = visitMinutes
            self.encounterID = encounterID
            self.facility = facility
            self.startsAt = startsAt
            self.durationMinutes = durationMinutes
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCareGapEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LegacyCareGapEstimateStatus.rejected || next == LegacyCareGapEstimateStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LegacyCareGapEstimateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCareGapEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy care gap estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy care gap estimate") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(startsAt) * ratio * 100).rounded() / 100
        }

        func copyValue() -> LegacyCareGapEstimate {
            return LegacyCareGapEstimate(
                code: code,
                name: name,
                clinicianID: clinicianID,
                visitMinutes: visitMinutes,
                encounterID: encounterID,
                facility: facility,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy care gap estimate in status proposed.
    static func newLegacyCareGapEstimate(_ code: String, name: String) -> LegacyCareGapEstimate {
        return LegacyCareGapEstimate(
            code: code,
            name: name,
            clinicianID: "",
            visitMinutes: 0,
            encounterID: "",
            facility: "",
            startsAt: 0,
            durationMinutes: 0,
            ratio: 0.0,
            status: LegacyCareGapEstimateStatus.proposed
        )
    }
}
