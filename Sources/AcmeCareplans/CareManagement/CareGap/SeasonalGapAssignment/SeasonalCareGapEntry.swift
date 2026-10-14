import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal care gap entry is in its life cycle.
    enum SeasonalCareGapEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One seasonal care gap entry, with what the planners need to act on it.
    final class SeasonalCareGapEntry {
        var code: String
        var title: String
        var currency: String
        var allergy: String
        var ward: String
        var copay: Double
        var version: Int
        var ceiling: Double
        var status: SeasonalCareGapEntryStatus

        init(code: String, title: String, currency: String, allergy: String, ward: String, copay: Double, version: Int, ceiling: Double, status: SeasonalCareGapEntryStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.allergy = allergy
            self.ward = ward
            self.copay = copay
            self.version = version
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalCareGapEntryStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SeasonalCareGapEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care gap entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((ceiling + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCareGapEntry {
            return SeasonalCareGapEntry(
                code: code,
                title: title,
                currency: currency,
                allergy: allergy,
                ward: ward,
                copay: copay,
                version: version,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a seasonal care gap entry in status open.
    static func newSeasonalCareGapEntry(_ code: String, title: String) -> SeasonalCareGapEntry {
        return SeasonalCareGapEntry(
            code: code,
            title: title,
            currency: "",
            allergy: "",
            ward: "",
            copay: 0.0,
            version: 0,
            ceiling: 0.0,
            status: SeasonalCareGapEntryStatus.`open`
        )
    }
}
