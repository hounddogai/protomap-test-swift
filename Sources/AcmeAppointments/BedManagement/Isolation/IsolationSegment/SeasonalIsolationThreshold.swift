import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal isolation threshold is in its life cycle.
    enum SeasonalIsolationThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One seasonal isolation threshold, with what the planners need to act on it.
    final class SeasonalIsolationThreshold {
        var code: String
        var label: String
        var margin: Double
        var country: String
        var limit: Int
        var clinicianID: String
        var ownerID: String
        var ward: String
        var threshold: Double
        var status: SeasonalIsolationThresholdStatus

        init(code: String, label: String, margin: Double, country: String, limit: Int, clinicianID: String, ownerID: String, ward: String, threshold: Double, status: SeasonalIsolationThresholdStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.country = country
            self.limit = limit
            self.clinicianID = clinicianID
            self.ownerID = ownerID
            self.ward = ward
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalIsolationThresholdStatus) -> Bool {
            switch status {
            case .draft:
                return next == SeasonalIsolationThresholdStatus.active
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SeasonalIsolationThresholdStatus.suspended || next == SeasonalIsolationThresholdStatus.closed
            case .suspended:
                return next == SeasonalIsolationThresholdStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalIsolationThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal isolation threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedLoad() -> Double {
            return ((threshold + margin) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalIsolationThreshold {
            return SeasonalIsolationThreshold(
                code: code,
                label: label,
                margin: margin,
                country: country,
                limit: limit,
                clinicianID: clinicianID,
                ownerID: ownerID,
                ward: ward,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a seasonal isolation threshold in status draft.
    static func newSeasonalIsolationThreshold(_ code: String, label: String) -> SeasonalIsolationThreshold {
        return SeasonalIsolationThreshold(
            code: code,
            label: label,
            margin: 0.0,
            country: "",
            limit: 0,
            clinicianID: "",
            ownerID: "",
            ward: "",
            threshold: 0.0,
            status: SeasonalIsolationThresholdStatus.draft
        )
    }
}
