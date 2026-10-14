import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional language tier is in its life cycle.
    enum RegionalLanguageTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional language tier. Its code is unique within a tenant.
    final class RegionalLanguageTier {
        var code: String
        var name: String
        var category: String
        var batchSize: Int
        var description: String
        var attempts: Int
        var endsAt: Int
        var status: RegionalLanguageTierStatus

        init(code: String, name: String, category: String, batchSize: Int, description: String, attempts: Int, endsAt: Int, status: RegionalLanguageTierStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.batchSize = batchSize
            self.description = description
            self.attempts = attempts
            self.endsAt = endsAt
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

        func canMoveTo(_ next: RegionalLanguageTierStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalLanguageTierStatus.reopened || next == RegionalLanguageTierStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RegionalLanguageTierStatus.reopened || next == RegionalLanguageTierStatus.archived
            case .reopened:
                return next == RegionalLanguageTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalLanguageTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional language tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedLoad() -> Double {
            return ((Double(batchSize) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalLanguageTier {
            return RegionalLanguageTier(
                code: code,
                name: name,
                category: category,
                batchSize: batchSize,
                description: description,
                attempts: attempts,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional language tier in status open.
    static func newRegionalLanguageTier(_ code: String, name: String) -> RegionalLanguageTier {
        return RegionalLanguageTier(
            code: code,
            name: name,
            category: "",
            batchSize: 0,
            description: "",
            attempts: 0,
            endsAt: 0,
            status: RegionalLanguageTierStatus.`open`
        )
    }
}
