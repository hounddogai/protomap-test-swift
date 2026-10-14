import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional consent form threshold is in its life cycle.
    enum RegionalConsentFormThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional consent form threshold as the consent form team keeps it.
    final class RegionalConsentFormThreshold {
        var code: String
        var title: String
        var active: Bool
        var allergy: String
        var clinicianID: String
        var limit: Int
        var locale: String
        var externalRef: String
        var sequence: Int
        var bed: String
        var rate: Double
        var status: RegionalConsentFormThresholdStatus

        init(code: String, title: String, active: Bool, allergy: String, clinicianID: String, limit: Int, locale: String, externalRef: String, sequence: Int, bed: String, rate: Double, status: RegionalConsentFormThresholdStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.allergy = allergy
            self.clinicianID = clinicianID
            self.limit = limit
            self.locale = locale
            self.externalRef = externalRef
            self.sequence = sequence
            self.bed = bed
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalConsentFormThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RegionalConsentFormThresholdStatus.completed || next == RegionalConsentFormThresholdStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalConsentFormThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalConsentFormThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional consent form threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional consent form threshold") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((rate + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalConsentFormThreshold {
            return RegionalConsentFormThreshold(
                code: code,
                title: title,
                active: active,
                allergy: allergy,
                clinicianID: clinicianID,
                limit: limit,
                locale: locale,
                externalRef: externalRef,
                sequence: sequence,
                bed: bed,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional consent form threshold in status planned.
    static func newRegionalConsentFormThreshold(_ code: String, title: String) -> RegionalConsentFormThreshold {
        return RegionalConsentFormThreshold(
            code: code,
            title: title,
            active: false,
            allergy: "",
            clinicianID: "",
            limit: 0,
            locale: "",
            externalRef: "",
            sequence: 0,
            bed: "",
            rate: 0.0,
            status: RegionalConsentFormThresholdStatus.planned
        )
    }
}
