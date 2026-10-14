import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted risk score summary is in its life cycle.
    enum WeightedRiskScoreSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a weighted risk score summary and its current status.
    final class WeightedRiskScoreSummary {
        var code: String
        var label: String
        var contactEmail: String
        var phone: String
        var margin: Double
        var diagnosisCode: String
        var channel: String
        var startsAt: Int
        var status: WeightedRiskScoreSummaryStatus

        init(code: String, label: String, contactEmail: String, phone: String, margin: Double, diagnosisCode: String, channel: String, startsAt: Int, status: WeightedRiskScoreSummaryStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.phone = phone
            self.margin = margin
            self.diagnosisCode = diagnosisCode
            self.channel = channel
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedRiskScoreSummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedRiskScoreSummaryStatus.granted || next == WeightedRiskScoreSummaryStatus.revoked
            case .granted:
                return next == WeightedRiskScoreSummaryStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: WeightedRiskScoreSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted risk score summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return (Double(startsAt) * margin * 100).rounded() / 100
        }

        func copyValue() -> WeightedRiskScoreSummary {
            return WeightedRiskScoreSummary(
                code: code,
                label: label,
                contactEmail: contactEmail,
                phone: phone,
                margin: margin,
                diagnosisCode: diagnosisCode,
                channel: channel,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted risk score summary in status requested.
    static func newWeightedRiskScoreSummary(_ code: String, label: String) -> WeightedRiskScoreSummary {
        return WeightedRiskScoreSummary(
            code: code,
            label: label,
            contactEmail: "",
            phone: "",
            margin: 0.0,
            diagnosisCode: "",
            channel: "",
            startsAt: 0,
            status: WeightedRiskScoreSummaryStatus.requested
        )
    }
}
