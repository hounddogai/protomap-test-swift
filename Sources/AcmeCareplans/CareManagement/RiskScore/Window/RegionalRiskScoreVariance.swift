import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional risk score variance is in its life cycle.
    enum RegionalRiskScoreVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional risk score variance as the risk score team keeps it.
    final class RegionalRiskScoreVariance {
        var code: String
        var title: String
        var contactEmail: String
        var rate: Double
        var facility: String
        var approved: Bool
        var margin: Double
        var floorValue: Double
        var status: RegionalRiskScoreVarianceStatus

        init(code: String, title: String, contactEmail: String, rate: Double, facility: String, approved: Bool, margin: Double, floorValue: Double, status: RegionalRiskScoreVarianceStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.rate = rate
            self.facility = facility
            self.approved = approved
            self.margin = margin
            self.floorValue = floorValue
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

        func canMoveTo(_ next: RegionalRiskScoreVarianceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
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

        func moveTo(_ next: RegionalRiskScoreVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional risk score variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedTotal() -> Double {
            return ((rate - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRiskScoreVariance {
            return RegionalRiskScoreVariance(
                code: code,
                title: title,
                contactEmail: contactEmail,
                rate: rate,
                facility: facility,
                approved: approved,
                margin: margin,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional risk score variance in status created.
    static func newRegionalRiskScoreVariance(_ code: String, title: String) -> RegionalRiskScoreVariance {
        return RegionalRiskScoreVariance(
            code: code,
            title: title,
            contactEmail: "",
            rate: 0.0,
            facility: "",
            approved: false,
            margin: 0.0,
            floorValue: 0.0,
            status: RegionalRiskScoreVarianceStatus.created
        )
    }
}
