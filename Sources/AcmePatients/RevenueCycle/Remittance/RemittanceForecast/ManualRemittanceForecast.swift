import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual remittance forecast is in its life cycle.
    enum ManualRemittanceForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual remittance forecast as the remittance team keeps it.
    final class ManualRemittanceForecast {
        var code: String
        var title: String
        var country: String
        var acuity: Int
        var category: String
        var archived: Bool
        var procedureCode: String
        var retries: Int
        var status: ManualRemittanceForecastStatus

        init(code: String, title: String, country: String, acuity: Int, category: String, archived: Bool, procedureCode: String, retries: Int, status: ManualRemittanceForecastStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.acuity = acuity
            self.category = category
            self.archived = archived
            self.procedureCode = procedureCode
            self.retries = retries
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

        func canMoveTo(_ next: ManualRemittanceForecastStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualRemittanceForecastStatus.approved || next == ManualRemittanceForecastStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ManualRemittanceForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual remittance forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual remittance forecast") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(acuity) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ManualRemittanceForecast {
            return ManualRemittanceForecast(
                code: code,
                title: title,
                country: country,
                acuity: acuity,
                category: category,
                archived: archived,
                procedureCode: procedureCode,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual remittance forecast in status proposed.
    static func newManualRemittanceForecast(_ code: String, title: String) -> ManualRemittanceForecast {
        return ManualRemittanceForecast(
            code: code,
            title: title,
            country: "",
            acuity: 0,
            category: "",
            archived: false,
            procedureCode: "",
            retries: 0,
            status: ManualRemittanceForecastStatus.proposed
        )
    }
}
