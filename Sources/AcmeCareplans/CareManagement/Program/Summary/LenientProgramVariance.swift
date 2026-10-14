import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient program variance is in its life cycle.
    enum LenientProgramVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One lenient program variance, with what the planners need to act on it.
    final class LenientProgramVariance {
        var code: String
        var name: String
        var amount: Double
        var contactEmail: String
        var timezone: String
        var revision: Int
        var threshold: Double
        var quantity: Int
        var region: String
        var attempts: Int
        var archived: Bool
        var status: LenientProgramVarianceStatus

        init(code: String, name: String, amount: Double, contactEmail: String, timezone: String, revision: Int, threshold: Double, quantity: Int, region: String, attempts: Int, archived: Bool, status: LenientProgramVarianceStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.contactEmail = contactEmail
            self.timezone = timezone
            self.revision = revision
            self.threshold = threshold
            self.quantity = quantity
            self.region = region
            self.attempts = attempts
            self.archived = archived
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

        func canMoveTo(_ next: LenientProgramVarianceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LenientProgramVarianceStatus.closed
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

        func moveTo(_ next: LenientProgramVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient program variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedVolume() -> Double {
            return ((Double(attempts) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> LenientProgramVariance {
            return LenientProgramVariance(
                code: code,
                name: name,
                amount: amount,
                contactEmail: contactEmail,
                timezone: timezone,
                revision: revision,
                threshold: threshold,
                quantity: quantity,
                region: region,
                attempts: attempts,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient program variance in status draft.
    static func newLenientProgramVariance(_ code: String, name: String) -> LenientProgramVariance {
        return LenientProgramVariance(
            code: code,
            name: name,
            amount: 0.0,
            contactEmail: "",
            timezone: "",
            revision: 0,
            threshold: 0.0,
            quantity: 0,
            region: "",
            attempts: 0,
            archived: false,
            status: LenientProgramVarianceStatus.draft
        )
    }
}
