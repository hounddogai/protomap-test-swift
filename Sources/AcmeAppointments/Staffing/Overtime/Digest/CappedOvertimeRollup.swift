import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped overtime rollup is in its life cycle.
    enum CappedOvertimeRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped overtime rollup. Its code is unique within a tenant.
    final class CappedOvertimeRollup {
        var code: String
        var name: String
        var amount: Double
        var checksum: String
        var phone: String
        var externalRef: String
        var source: String
        var minimum: Double
        var archived: Bool
        var status: CappedOvertimeRollupStatus

        init(code: String, name: String, amount: Double, checksum: String, phone: String, externalRef: String, source: String, minimum: Double, archived: Bool, status: CappedOvertimeRollupStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.checksum = checksum
            self.phone = phone
            self.externalRef = externalRef
            self.source = source
            self.minimum = minimum
            self.archived = archived
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

        func canMoveTo(_ next: CappedOvertimeRollupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CappedOvertimeRollupStatus.reopened || next == CappedOvertimeRollupStatus.archived
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

        func moveTo(_ next: CappedOvertimeRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped overtime rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return (minimum * amount * 100).rounded() / 100
        }

        func copyValue() -> CappedOvertimeRollup {
            return CappedOvertimeRollup(
                code: code,
                name: name,
                amount: amount,
                checksum: checksum,
                phone: phone,
                externalRef: externalRef,
                source: source,
                minimum: minimum,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped overtime rollup in status open.
    static func newCappedOvertimeRollup(_ code: String, name: String) -> CappedOvertimeRollup {
        return CappedOvertimeRollup(
            code: code,
            name: name,
            amount: 0.0,
            checksum: "",
            phone: "",
            externalRef: "",
            source: "",
            minimum: 0.0,
            archived: false,
            status: CappedOvertimeRollupStatus.`open`
        )
    }
}
