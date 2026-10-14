import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal care gap tier is in its life cycle.
    enum SeasonalCareGapTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal care gap tier. Its code is unique within a tenant.
    final class SeasonalCareGapTier {
        var code: String
        var name: String
        var unit: String
        var facility: String
        var phone: String
        var ownerID: String
        var specialty: String
        var score: Double
        var status: SeasonalCareGapTierStatus

        init(code: String, name: String, unit: String, facility: String, phone: String, ownerID: String, specialty: String, score: Double, status: SeasonalCareGapTierStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.facility = facility
            self.phone = phone
            self.ownerID = ownerID
            self.specialty = specialty
            self.score = score
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

        func canMoveTo(_ next: SeasonalCareGapTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalCareGapTierStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCareGapTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care gap tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal care gap tier") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> SeasonalCareGapTier {
            return SeasonalCareGapTier(
                code: code,
                name: name,
                unit: unit,
                facility: facility,
                phone: phone,
                ownerID: ownerID,
                specialty: specialty,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a seasonal care gap tier in status new.
    static func newSeasonalCareGapTier(_ code: String, name: String) -> SeasonalCareGapTier {
        return SeasonalCareGapTier(
            code: code,
            name: name,
            unit: "",
            facility: "",
            phone: "",
            ownerID: "",
            specialty: "",
            score: 0.0,
            status: SeasonalCareGapTierStatus.new
        )
    }
}
