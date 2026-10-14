import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution variance is in its life cycle.
    enum SubstitutionVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a substitution variance and its current status.
    final class SubstitutionVariance {
        var code: String
        var label: String
        var cost: Double
        var attributes: [String: String]
        var acuity: Int
        var ownerID: String
        var summary: String
        var maximum: Double
        var rate: Double
        var createdAt: Int
        var title: String
        var status: SubstitutionVarianceStatus

        init(code: String, label: String, cost: Double, attributes: [String: String], acuity: Int, ownerID: String, summary: String, maximum: Double, rate: Double, createdAt: Int, title: String, status: SubstitutionVarianceStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.attributes = attributes
            self.acuity = acuity
            self.ownerID = ownerID
            self.summary = summary
            self.maximum = maximum
            self.rate = rate
            self.createdAt = createdAt
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SubstitutionVarianceStatus) -> Bool {
            switch status {
            case .draft:
                return next == SubstitutionVarianceStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SubstitutionVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("substitution variance") \(code)"
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

        func netTotal() -> Double {
            return ((cost + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionVariance {
            return SubstitutionVariance(
                code: code,
                label: label,
                cost: cost,
                attributes: attributes,
                acuity: acuity,
                ownerID: ownerID,
                summary: summary,
                maximum: maximum,
                rate: rate,
                createdAt: createdAt,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a substitution variance in status draft.
    static func newSubstitutionVariance(_ code: String, label: String) -> SubstitutionVariance {
        return SubstitutionVariance(
            code: code,
            label: label,
            cost: 0.0,
            attributes: [:],
            acuity: 0,
            ownerID: "",
            summary: "",
            maximum: 0.0,
            rate: 0.0,
            createdAt: 0,
            title: "",
            status: SubstitutionVarianceStatus.draft
        )
    }
}
