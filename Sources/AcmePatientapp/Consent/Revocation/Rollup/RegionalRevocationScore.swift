import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional revocation score is in its life cycle.
    enum RegionalRevocationScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One regional revocation score, with what the planners need to act on it.
    final class RegionalRevocationScore {
        var code: String
        var label: String
        var country: String
        var patientRef: String
        var amount: Double
        var diagnosisCode: String
        var sequence: Int
        var summary: String
        var name: String
        var phone: String
        var capacity: Int
        var status: RegionalRevocationScoreStatus

        init(code: String, label: String, country: String, patientRef: String, amount: Double, diagnosisCode: String, sequence: Int, summary: String, name: String, phone: String, capacity: Int, status: RegionalRevocationScoreStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.patientRef = patientRef
            self.amount = amount
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.summary = summary
            self.name = name
            self.phone = phone
            self.capacity = capacity
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

        func canMoveTo(_ next: RegionalRevocationScoreStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RegionalRevocationScoreStatus.archived
            case .reopened:
                return next == RegionalRevocationScoreStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalRevocationScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional revocation score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedValue() -> Double {
            return ((Double(capacity) + amount) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRevocationScore {
            return RegionalRevocationScore(
                code: code,
                label: label,
                country: country,
                patientRef: patientRef,
                amount: amount,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                summary: summary,
                name: name,
                phone: phone,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional revocation score in status open.
    static func newRegionalRevocationScore(_ code: String, label: String) -> RegionalRevocationScore {
        return RegionalRevocationScore(
            code: code,
            label: label,
            country: "",
            patientRef: "",
            amount: 0.0,
            diagnosisCode: "",
            sequence: 0,
            summary: "",
            name: "",
            phone: "",
            capacity: 0,
            status: RegionalRevocationScoreStatus.`open`
        )
    }
}
