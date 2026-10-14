import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form request is in its life cycle.
    enum ConsentFormRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One consent form request, with what the planners need to act on it.
    final class ConsentFormRequest {
        var code: String
        var label: String
        var budget: Double
        var expiresAt: Int
        var ward: String
        var description: String
        var status: ConsentFormRequestStatus

        init(code: String, label: String, budget: Double, expiresAt: Int, ward: String, description: String, status: ConsentFormRequestStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.expiresAt = expiresAt
            self.ward = ward
            self.description = description
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

        func canMoveTo(_ next: ConsentFormRequestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ConsentFormRequestStatus.rejected
            case .rejected:
                return next == ConsentFormRequestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedVolume() -> Double {
            return (budget * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormRequest {
            return ConsentFormRequest(
                code: code,
                label: label,
                budget: budget,
                expiresAt: expiresAt,
                ward: ward,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a consent form request in status proposed.
    static func newConsentFormRequest(_ code: String, label: String) -> ConsentFormRequest {
        return ConsentFormRequest(
            code: code,
            label: label,
            budget: 0.0,
            expiresAt: 0,
            ward: "",
            description: "",
            status: ConsentFormRequestStatus.proposed
        )
    }
}
