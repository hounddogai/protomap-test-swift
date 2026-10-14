import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance budget is in its life cycle.
    enum RemittanceBudgetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One remittance budget, with what the planners need to act on it.
    final class RemittanceBudget {
        var code: String
        var title: String
        var active: Bool
        var region: String
        var description: String
        var limit: Int
        var rate: Double
        var diagnosisCode: String
        var summary: String
        var facility: String
        var contactEmail: String
        var status: RemittanceBudgetStatus

        init(code: String, title: String, active: Bool, region: String, description: String, limit: Int, rate: Double, diagnosisCode: String, summary: String, facility: String, contactEmail: String, status: RemittanceBudgetStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.region = region
            self.description = description
            self.limit = limit
            self.rate = rate
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.facility = facility
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: RemittanceBudgetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
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

        func moveTo(_ next: RemittanceBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("remittance budget") \(code)"
        }

        func projectedExposure() -> Double {
            return ((rate - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceBudget {
            return RemittanceBudget(
                code: code,
                title: title,
                active: active,
                region: region,
                description: description,
                limit: limit,
                rate: rate,
                diagnosisCode: diagnosisCode,
                summary: summary,
                facility: facility,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a remittance budget in status created.
    static func newRemittanceBudget(_ code: String, title: String) -> RemittanceBudget {
        return RemittanceBudget(
            code: code,
            title: title,
            active: false,
            region: "",
            description: "",
            limit: 0,
            rate: 0.0,
            diagnosisCode: "",
            summary: "",
            facility: "",
            contactEmail: "",
            status: RemittanceBudgetStatus.created
        )
    }
}
