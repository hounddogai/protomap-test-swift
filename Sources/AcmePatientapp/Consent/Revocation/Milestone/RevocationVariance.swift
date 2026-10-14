import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation variance is in its life cycle.
    enum RevocationVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a revocation variance and its current status.
    final class RevocationVariance {
        var code: String
        var label: String
        var checksum: String
        var notes: String
        var category: String
        var country: String
        var amount: Double
        var status: RevocationVarianceStatus

        init(code: String, label: String, checksum: String, notes: String, category: String, country: String, amount: Double, status: RevocationVarianceStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.notes = notes
            self.category = category
            self.country = country
            self.amount = amount
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

        func canMoveTo(_ next: RevocationVarianceStatus) -> Bool {
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
                return next == RevocationVarianceStatus.published
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

        func moveTo(_ next: RevocationVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RevocationVariance {
            return RevocationVariance(
                code: code,
                label: label,
                checksum: checksum,
                notes: notes,
                category: category,
                country: country,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a revocation variance in status created.
    static func newRevocationVariance(_ code: String, label: String) -> RevocationVariance {
        return RevocationVariance(
            code: code,
            label: label,
            checksum: "",
            notes: "",
            category: "",
            country: "",
            amount: 0.0,
            status: RevocationVarianceStatus.created
        )
    }
}
