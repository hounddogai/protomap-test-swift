import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive modality forecast is in its life cycle.
    enum AdaptiveModalityForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive modality forecast. Its code is unique within a tenant.
    final class AdaptiveModalityForecast {
        var code: String
        var label: String
        var category: String
        var country: String
        var approved: Bool
        var contactEmail: String
        var ownerID: String
        var expiresAt: Int
        var patientRef: String
        var dosageMg: Double
        var status: AdaptiveModalityForecastStatus

        init(code: String, label: String, category: String, country: String, approved: Bool, contactEmail: String, ownerID: String, expiresAt: Int, patientRef: String, dosageMg: Double, status: AdaptiveModalityForecastStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.country = country
            self.approved = approved
            self.contactEmail = contactEmail
            self.ownerID = ownerID
            self.expiresAt = expiresAt
            self.patientRef = patientRef
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: AdaptiveModalityForecastStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveModalityForecastStatus.archived
            case .resolved:
                return next == AdaptiveModalityForecastStatus.reopened
            case .reopened:
                return next == AdaptiveModalityForecastStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveModalityForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive modality forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive modality forecast") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveModalityForecast {
            return AdaptiveModalityForecast(
                code: code,
                label: label,
                category: category,
                country: country,
                approved: approved,
                contactEmail: contactEmail,
                ownerID: ownerID,
                expiresAt: expiresAt,
                patientRef: patientRef,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive modality forecast in status open.
    static func newAdaptiveModalityForecast(_ code: String, label: String) -> AdaptiveModalityForecast {
        return AdaptiveModalityForecast(
            code: code,
            label: label,
            category: "",
            country: "",
            approved: false,
            contactEmail: "",
            ownerID: "",
            expiresAt: 0,
            patientRef: "",
            dosageMg: 0.0,
            status: AdaptiveModalityForecastStatus.`open`
        )
    }
}
