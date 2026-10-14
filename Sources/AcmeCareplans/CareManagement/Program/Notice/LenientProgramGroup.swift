import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient program group is in its life cycle.
    enum LenientProgramGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient program group. Its code is unique within a tenant.
    final class LenientProgramGroup {
        var code: String
        var label: String
        var tags: [String]
        var startsAt: Int
        var quantity: Int
        var copay: Double
        var currency: String
        var score: Double
        var status: LenientProgramGroupStatus

        init(code: String, label: String, tags: [String], startsAt: Int, quantity: Int, copay: Double, currency: String, score: Double, status: LenientProgramGroupStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.startsAt = startsAt
            self.quantity = quantity
            self.copay = copay
            self.currency = currency
            self.score = score
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

        func canMoveTo(_ next: LenientProgramGroupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientProgramGroupStatus.resolved || next == LenientProgramGroupStatus.archived
            case .inReview:
                return next == LenientProgramGroupStatus.resolved
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LenientProgramGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientProgramGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient program group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return (score * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> LenientProgramGroup {
            return LenientProgramGroup(
                code: code,
                label: label,
                tags: tags,
                startsAt: startsAt,
                quantity: quantity,
                copay: copay,
                currency: currency,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient program group in status open.
    static func newLenientProgramGroup(_ code: String, label: String) -> LenientProgramGroup {
        return LenientProgramGroup(
            code: code,
            label: label,
            tags: [],
            startsAt: 0,
            quantity: 0,
            copay: 0.0,
            currency: "",
            score: 0.0,
            status: LenientProgramGroupStatus.`open`
        )
    }
}
