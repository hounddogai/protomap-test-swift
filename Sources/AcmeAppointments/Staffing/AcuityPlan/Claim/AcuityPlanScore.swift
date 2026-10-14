import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan score is in its life cycle.
    enum AcuityPlanScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a acuity plan score and its current status.
    final class AcuityPlanScore {
        var code: String
        var name: String
        var rate: Double
        var clinicianID: String
        var amount: Double
        var unit: String
        var country: String
        var region: String
        var status: AcuityPlanScoreStatus

        init(code: String, name: String, rate: Double, clinicianID: String, amount: Double, unit: String, country: String, region: String, status: AcuityPlanScoreStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.clinicianID = clinicianID
            self.amount = amount
            self.unit = unit
            self.country = country
            self.region = region
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

        func canMoveTo(_ next: AcuityPlanScoreStatus) -> Bool {
            switch status {
            case .new:
                return next == AcuityPlanScoreStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AcuityPlanScoreStatus.done || next == AcuityPlanScoreStatus.failed
            case .done:
                return next == AcuityPlanScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return ((rate + amount) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanScore {
            return AcuityPlanScore(
                code: code,
                name: name,
                rate: rate,
                clinicianID: clinicianID,
                amount: amount,
                unit: unit,
                country: country,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a acuity plan score in status new.
    static func newAcuityPlanScore(_ code: String, name: String) -> AcuityPlanScore {
        return AcuityPlanScore(
            code: code,
            name: name,
            rate: 0.0,
            clinicianID: "",
            amount: 0.0,
            unit: "",
            country: "",
            region: "",
            status: AcuityPlanScoreStatus.new
        )
    }
}
