import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool window is in its life cycle.
    enum FloatPoolWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A float pool window as the float pool team keeps it.
    final class FloatPoolWindow {
        var code: String
        var label: String
        var quantity: Int
        var endsAt: Int
        var diagnosisCode: String
        var expiresAt: Int
        var active: Bool
        var contactEmail: String
        var budget: Double
        var summary: String
        var segment: String
        var status: FloatPoolWindowStatus

        init(code: String, label: String, quantity: Int, endsAt: Int, diagnosisCode: String, expiresAt: Int, active: Bool, contactEmail: String, budget: Double, summary: String, segment: String, status: FloatPoolWindowStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.endsAt = endsAt
            self.diagnosisCode = diagnosisCode
            self.expiresAt = expiresAt
            self.active = active
            self.contactEmail = contactEmail
            self.budget = budget
            self.summary = summary
            self.segment = segment
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

        func canMoveTo(_ next: FloatPoolWindowStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FloatPoolWindowStatus.reopened || next == FloatPoolWindowStatus.archived
            case .reopened:
                return next == FloatPoolWindowStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("float pool window") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(endsAt) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolWindow {
            return FloatPoolWindow(
                code: code,
                label: label,
                quantity: quantity,
                endsAt: endsAt,
                diagnosisCode: diagnosisCode,
                expiresAt: expiresAt,
                active: active,
                contactEmail: contactEmail,
                budget: budget,
                summary: summary,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a float pool window in status open.
    static func newFloatPoolWindow(_ code: String, label: String) -> FloatPoolWindow {
        return FloatPoolWindow(
            code: code,
            label: label,
            quantity: 0,
            endsAt: 0,
            diagnosisCode: "",
            expiresAt: 0,
            active: false,
            contactEmail: "",
            budget: 0.0,
            summary: "",
            segment: "",
            status: FloatPoolWindowStatus.`open`
        )
    }
}
