import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary care gap group is in its life cycle.
    enum PrimaryCareGapGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary care gap group. Its code is unique within a tenant.
    final class PrimaryCareGapGroup {
        var code: String
        var label: String
        var payer: String
        var procedureCode: String
        var category: String
        var tags: [String]
        var version: Int
        var timezone: String
        var createdAt: Int
        var startsAt: Int
        var reviewer: String
        var status: PrimaryCareGapGroupStatus

        init(code: String, label: String, payer: String, procedureCode: String, category: String, tags: [String], version: Int, timezone: String, createdAt: Int, startsAt: Int, reviewer: String, status: PrimaryCareGapGroupStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.procedureCode = procedureCode
            self.category = category
            self.tags = tags
            self.version = version
            self.timezone = timezone
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.reviewer = reviewer
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

        func canMoveTo(_ next: PrimaryCareGapGroupStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryCareGapGroupStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryCareGapGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary care gap group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return (Double(createdAt) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCareGapGroup {
            return PrimaryCareGapGroup(
                code: code,
                label: label,
                payer: payer,
                procedureCode: procedureCode,
                category: category,
                tags: tags,
                version: version,
                timezone: timezone,
                createdAt: createdAt,
                startsAt: startsAt,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a primary care gap group in status created.
    static func newPrimaryCareGapGroup(_ code: String, label: String) -> PrimaryCareGapGroup {
        return PrimaryCareGapGroup(
            code: code,
            label: label,
            payer: "",
            procedureCode: "",
            category: "",
            tags: [],
            version: 0,
            timezone: "",
            createdAt: 0,
            startsAt: 0,
            reviewer: "",
            status: PrimaryCareGapGroupStatus.created
        )
    }
}
