import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default cleaning digest is in its life cycle.
    enum DefaultCleaningDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A default cleaning digest. Its code is unique within a tenant.
    final class DefaultCleaningDigest {
        var code: String
        var title: String
        var diagnosisCode: String
        var copay: Double
        var cost: Double
        var label: String
        var quantity: Int
        var summary: String
        var status: DefaultCleaningDigestStatus

        init(code: String, title: String, diagnosisCode: String, copay: Double, cost: Double, label: String, quantity: Int, summary: String, status: DefaultCleaningDigestStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.copay = copay
            self.cost = cost
            self.label = label
            self.quantity = quantity
            self.summary = summary
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

        func canMoveTo(_ next: DefaultCleaningDigestStatus) -> Bool {
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
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == DefaultCleaningDigestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCleaningDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default cleaning digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("default cleaning digest") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(quantity) - copay) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCleaningDigest {
            return DefaultCleaningDigest(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                copay: copay,
                cost: cost,
                label: label,
                quantity: quantity,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default cleaning digest in status open.
    static func newDefaultCleaningDigest(_ code: String, title: String) -> DefaultCleaningDigest {
        return DefaultCleaningDigest(
            code: code,
            title: title,
            diagnosisCode: "",
            copay: 0.0,
            cost: 0.0,
            label: "",
            quantity: 0,
            summary: "",
            status: DefaultCleaningDigestStatus.`open`
        )
    }
}
