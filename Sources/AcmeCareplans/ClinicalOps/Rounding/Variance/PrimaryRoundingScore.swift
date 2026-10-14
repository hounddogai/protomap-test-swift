import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary rounding score is in its life cycle.
    enum PrimaryRoundingScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary rounding score and its current status.
    final class PrimaryRoundingScore {
        var code: String
        var label: String
        var locale: String
        var tags: [String]
        var checksum: String
        var amount: Double
        var status: PrimaryRoundingScoreStatus

        init(code: String, label: String, locale: String, tags: [String], checksum: String, amount: Double, status: PrimaryRoundingScoreStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.tags = tags
            self.checksum = checksum
            self.amount = amount
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

        func canMoveTo(_ next: PrimaryRoundingScoreStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PrimaryRoundingScoreStatus.suspended || next == PrimaryRoundingScoreStatus.closed
            case .active:
                return next == PrimaryRoundingScoreStatus.suspended || next == PrimaryRoundingScoreStatus.closed
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

        func moveTo(_ next: PrimaryRoundingScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary rounding score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary rounding score") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> PrimaryRoundingScore {
            return PrimaryRoundingScore(
                code: code,
                label: label,
                locale: locale,
                tags: tags,
                checksum: checksum,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a primary rounding score in status draft.
    static func newPrimaryRoundingScore(_ code: String, label: String) -> PrimaryRoundingScore {
        return PrimaryRoundingScore(
            code: code,
            label: label,
            locale: "",
            tags: [],
            checksum: "",
            amount: 0.0,
            status: PrimaryRoundingScoreStatus.draft
        )
    }
}
