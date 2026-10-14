import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive modality request is in its life cycle.
    enum AdaptiveModalityRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive modality request. Its code is unique within a tenant.
    final class AdaptiveModalityRequest {
        var code: String
        var name: String
        var diagnosisCode: String
        var durationMinutes: Int
        var summary: String
        var graceDays: Int
        var amount: Double
        var startsAt: Int
        var score: Double
        var title: String
        var visitMinutes: Int
        var status: AdaptiveModalityRequestStatus

        init(code: String, name: String, diagnosisCode: String, durationMinutes: Int, summary: String, graceDays: Int, amount: Double, startsAt: Int, score: Double, title: String, visitMinutes: Int, status: AdaptiveModalityRequestStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.durationMinutes = durationMinutes
            self.summary = summary
            self.graceDays = graceDays
            self.amount = amount
            self.startsAt = startsAt
            self.score = score
            self.title = title
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: AdaptiveModalityRequestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveModalityRequestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveModalityRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive modality request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netExposure() -> Double {
            return ((Double(durationMinutes) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveModalityRequest {
            return AdaptiveModalityRequest(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                durationMinutes: durationMinutes,
                summary: summary,
                graceDays: graceDays,
                amount: amount,
                startsAt: startsAt,
                score: score,
                title: title,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive modality request in status proposed.
    static func newAdaptiveModalityRequest(_ code: String, name: String) -> AdaptiveModalityRequest {
        return AdaptiveModalityRequest(
            code: code,
            name: name,
            diagnosisCode: "",
            durationMinutes: 0,
            summary: "",
            graceDays: 0,
            amount: 0.0,
            startsAt: 0,
            score: 0.0,
            title: "",
            visitMinutes: 0,
            status: AdaptiveModalityRequestStatus.proposed
        )
    }
}
