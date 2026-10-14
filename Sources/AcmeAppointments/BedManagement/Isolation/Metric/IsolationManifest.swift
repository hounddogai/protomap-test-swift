import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation manifest is in its life cycle.
    enum IsolationManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A isolation manifest as the isolation team keeps it.
    final class IsolationManifest {
        var code: String
        var label: String
        var limit: Int
        var discount: Double
        var budget: Double
        var status: IsolationManifestStatus

        init(code: String, label: String, limit: Int, discount: Double, budget: Double, status: IsolationManifestStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.discount = discount
            self.budget = budget
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

        func canMoveTo(_ next: IsolationManifestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == IsolationManifestStatus.reopened
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == IsolationManifestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("isolation manifest") \(code)"
        }

        func weightedValue() -> Double {
            return ((discount - budget) * 100).rounded() / 100
        }

        func copyValue() -> IsolationManifest {
            return IsolationManifest(
                code: code,
                label: label,
                limit: limit,
                discount: discount,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a isolation manifest in status open.
    static func newIsolationManifest(_ code: String, label: String) -> IsolationManifest {
        return IsolationManifest(
            code: code,
            label: label,
            limit: 0,
            discount: 0.0,
            budget: 0.0,
            status: IsolationManifestStatus.`open`
        )
    }
}
