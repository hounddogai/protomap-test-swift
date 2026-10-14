import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary overtime summary is in its life cycle.
    enum PrimaryOvertimeSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary overtime summary as the overtime team keeps it.
    final class PrimaryOvertimeSummary {
        var code: String
        var title: String
        var threshold: Double
        var country: String
        var margin: Double
        var active: Bool
        var acuity: Int
        var description: String
        var attributes: [String: String]
        var updatedAt: Int
        var externalRef: String
        var status: PrimaryOvertimeSummaryStatus

        init(code: String, title: String, threshold: Double, country: String, margin: Double, active: Bool, acuity: Int, description: String, attributes: [String: String], updatedAt: Int, externalRef: String, status: PrimaryOvertimeSummaryStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.country = country
            self.margin = margin
            self.active = active
            self.acuity = acuity
            self.description = description
            self.attributes = attributes
            self.updatedAt = updatedAt
            self.externalRef = externalRef
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

        func canMoveTo(_ next: PrimaryOvertimeSummaryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryOvertimeSummaryStatus.approved || next == PrimaryOvertimeSummaryStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PrimaryOvertimeSummaryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryOvertimeSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary overtime summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func adjustedLoad() -> Double {
            return ((margin - threshold) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOvertimeSummary {
            return PrimaryOvertimeSummary(
                code: code,
                title: title,
                threshold: threshold,
                country: country,
                margin: margin,
                active: active,
                acuity: acuity,
                description: description,
                attributes: attributes,
                updatedAt: updatedAt,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary overtime summary in status proposed.
    static func newPrimaryOvertimeSummary(_ code: String, title: String) -> PrimaryOvertimeSummary {
        return PrimaryOvertimeSummary(
            code: code,
            title: title,
            threshold: 0.0,
            country: "",
            margin: 0.0,
            active: false,
            acuity: 0,
            description: "",
            attributes: [:],
            updatedAt: 0,
            externalRef: "",
            status: PrimaryOvertimeSummaryStatus.proposed
        )
    }
}
