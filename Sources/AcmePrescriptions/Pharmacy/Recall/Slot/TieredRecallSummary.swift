import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered recall summary is in its life cycle.
    enum TieredRecallSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered recall summary as the recall team keeps it.
    final class TieredRecallSummary {
        var code: String
        var label: String
        var diagnosisCode: String
        var checksum: String
        var attributes: [String: String]
        var patientRef: String
        var country: String
        var phone: String
        var amount: Double
        var status: TieredRecallSummaryStatus

        init(code: String, label: String, diagnosisCode: String, checksum: String, attributes: [String: String], patientRef: String, country: String, phone: String, amount: Double, status: TieredRecallSummaryStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.checksum = checksum
            self.attributes = attributes
            self.patientRef = patientRef
            self.country = country
            self.phone = phone
            self.amount = amount
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

        func canMoveTo(_ next: TieredRecallSummaryStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TieredRecallSummaryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRecallSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered recall summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> TieredRecallSummary {
            return TieredRecallSummary(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                checksum: checksum,
                attributes: attributes,
                patientRef: patientRef,
                country: country,
                phone: phone,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered recall summary in status requested.
    static func newTieredRecallSummary(_ code: String, label: String) -> TieredRecallSummary {
        return TieredRecallSummary(
            code: code,
            label: label,
            diagnosisCode: "",
            checksum: "",
            attributes: [:],
            patientRef: "",
            country: "",
            phone: "",
            amount: 0.0,
            status: TieredRecallSummaryStatus.requested
        )
    }
}
