import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession summary is in its life cycle.
    enum AccessionSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A accession summary as the accession team keeps it.
    final class AccessionSummary {
        var code: String
        var label: String
        var procedureCode: String
        var expiresAt: Int
        var graceDays: Int
        var category: String
        var limit: Int
        var score: Double
        var country: String
        var contactEmail: String
        var attributes: [String: String]
        var status: AccessionSummaryStatus

        init(code: String, label: String, procedureCode: String, expiresAt: Int, graceDays: Int, category: String, limit: Int, score: Double, country: String, contactEmail: String, attributes: [String: String], status: AccessionSummaryStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.expiresAt = expiresAt
            self.graceDays = graceDays
            self.category = category
            self.limit = limit
            self.score = score
            self.country = country
            self.contactEmail = contactEmail
            self.attributes = attributes
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

        func canMoveTo(_ next: AccessionSummaryStatus) -> Bool {
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
                return next == AccessionSummaryStatus.revoked || next == AccessionSummaryStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AccessionSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("accession summary") \(code)"
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

        func projectedVolume() -> Double {
            return (Double(limit) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> AccessionSummary {
            return AccessionSummary(
                code: code,
                label: label,
                procedureCode: procedureCode,
                expiresAt: expiresAt,
                graceDays: graceDays,
                category: category,
                limit: limit,
                score: score,
                country: country,
                contactEmail: contactEmail,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a accession summary in status requested.
    static func newAccessionSummary(_ code: String, label: String) -> AccessionSummary {
        return AccessionSummary(
            code: code,
            label: label,
            procedureCode: "",
            expiresAt: 0,
            graceDays: 0,
            category: "",
            limit: 0,
            score: 0.0,
            country: "",
            contactEmail: "",
            attributes: [:],
            status: AccessionSummaryStatus.requested
        )
    }
}
