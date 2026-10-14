import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range request is in its life cycle.
    enum ReferenceRangeRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A reference range request as the reference range team keeps it.
    final class ReferenceRangeRequest {
        var code: String
        var label: String
        var windowDays: Int
        var endsAt: Int
        var country: String
        var description: String
        var specialty: String
        var active: Bool
        var status: ReferenceRangeRequestStatus

        init(code: String, label: String, windowDays: Int, endsAt: Int, country: String, description: String, specialty: String, active: Bool, status: ReferenceRangeRequestStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.endsAt = endsAt
            self.country = country
            self.description = description
            self.specialty = specialty
            self.active = active
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

        func canMoveTo(_ next: ReferenceRangeRequestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
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

        func moveTo(_ next: ReferenceRangeRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return ((Double(endsAt) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeRequest {
            return ReferenceRangeRequest(
                code: code,
                label: label,
                windowDays: windowDays,
                endsAt: endsAt,
                country: country,
                description: description,
                specialty: specialty,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a reference range request in status proposed.
    static func newReferenceRangeRequest(_ code: String, label: String) -> ReferenceRangeRequest {
        return ReferenceRangeRequest(
            code: code,
            label: label,
            windowDays: 0,
            endsAt: 0,
            country: "",
            description: "",
            specialty: "",
            active: false,
            status: ReferenceRangeRequestStatus.proposed
        )
    }
}
