import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning group is in its life cycle.
    enum CleaningGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A cleaning group as the cleaning team keeps it.
    final class CleaningGroup {
        var code: String
        var name: String
        var acuity: Int
        var payer: String
        var expiresAt: Int
        var updatedAt: Int
        var country: String
        var summary: String
        var reviewer: String
        var externalRef: String
        var status: CleaningGroupStatus

        init(code: String, name: String, acuity: Int, payer: String, expiresAt: Int, updatedAt: Int, country: String, summary: String, reviewer: String, externalRef: String, status: CleaningGroupStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.payer = payer
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.country = country
            self.summary = summary
            self.reviewer = reviewer
            self.externalRef = externalRef
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

        func canMoveTo(_ next: CleaningGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
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
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CleaningGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("cleaning group") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(expiresAt) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningGroup {
            return CleaningGroup(
                code: code,
                name: name,
                acuity: acuity,
                payer: payer,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                country: country,
                summary: summary,
                reviewer: reviewer,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a cleaning group in status open.
    static func newCleaningGroup(_ code: String, name: String) -> CleaningGroup {
        return CleaningGroup(
            code: code,
            name: name,
            acuity: 0,
            payer: "",
            expiresAt: 0,
            updatedAt: 0,
            country: "",
            summary: "",
            reviewer: "",
            externalRef: "",
            status: CleaningGroupStatus.`open`
        )
    }
}
