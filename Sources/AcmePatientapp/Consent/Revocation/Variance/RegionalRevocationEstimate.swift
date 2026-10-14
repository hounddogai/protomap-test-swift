import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional revocation estimate is in its life cycle.
    enum RegionalRevocationEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional revocation estimate. Its code is unique within a tenant.
    final class RegionalRevocationEstimate {
        var code: String
        var title: String
        var diagnosisCode: String
        var region: String
        var acuity: Int
        var quantity: Int
        var category: String
        var facility: String
        var status: RegionalRevocationEstimateStatus

        init(code: String, title: String, diagnosisCode: String, region: String, acuity: Int, quantity: Int, category: String, facility: String, status: RegionalRevocationEstimateStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.region = region
            self.acuity = acuity
            self.quantity = quantity
            self.category = category
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalRevocationEstimateStatus) -> Bool {
            switch status {
            case .created:
                return next == RegionalRevocationEstimateStatus.published || next == RegionalRevocationEstimateStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RegionalRevocationEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional revocation estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional revocation estimate") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(acuity) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRevocationEstimate {
            return RegionalRevocationEstimate(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                region: region,
                acuity: acuity,
                quantity: quantity,
                category: category,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional revocation estimate in status created.
    static func newRegionalRevocationEstimate(_ code: String, title: String) -> RegionalRevocationEstimate {
        return RegionalRevocationEstimate(
            code: code,
            title: title,
            diagnosisCode: "",
            region: "",
            acuity: 0,
            quantity: 0,
            category: "",
            facility: "",
            status: RegionalRevocationEstimateStatus.created
        )
    }
}
