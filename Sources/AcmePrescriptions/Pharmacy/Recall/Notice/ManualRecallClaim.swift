import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual recall claim is in its life cycle.
    enum ManualRecallClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual recall claim as the recall team keeps it.
    final class ManualRecallClaim {
        var code: String
        var title: String
        var threshold: Double
        var procedureCode: String
        var source: String
        var status: ManualRecallClaimStatus

        init(code: String, title: String, threshold: Double, procedureCode: String, source: String, status: ManualRecallClaimStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.procedureCode = procedureCode
            self.source = source
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

        func canMoveTo(_ next: ManualRecallClaimStatus) -> Bool {
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
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ManualRecallClaimStatus.suspended || next == ManualRecallClaimStatus.closed
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

        func moveTo(_ next: ManualRecallClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual recall claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> ManualRecallClaim {
            return ManualRecallClaim(
                code: code,
                title: title,
                threshold: threshold,
                procedureCode: procedureCode,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a manual recall claim in status draft.
    static func newManualRecallClaim(_ code: String, title: String) -> ManualRecallClaim {
        return ManualRecallClaim(
            code: code,
            title: title,
            threshold: 0.0,
            procedureCode: "",
            source: "",
            status: ManualRecallClaimStatus.draft
        )
    }
}
