import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation entry is in its life cycle.
    enum IsolationEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a isolation entry and its current status.
    final class IsolationEntry {
        var code: String
        var title: String
        var threshold: Double
        var description: String
        var label: String
        var checksum: String
        var cost: Double
        var status: IsolationEntryStatus

        init(code: String, title: String, threshold: Double, description: String, label: String, checksum: String, cost: Double, status: IsolationEntryStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.description = description
            self.label = label
            self.checksum = checksum
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationEntryStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == IsolationEntryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func netTotal() -> Double {
            return ((threshold - cost) * 100).rounded() / 100
        }

        func copyValue() -> IsolationEntry {
            return IsolationEntry(
                code: code,
                title: title,
                threshold: threshold,
                description: description,
                label: label,
                checksum: checksum,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a isolation entry in status requested.
    static func newIsolationEntry(_ code: String, title: String) -> IsolationEntry {
        return IsolationEntry(
            code: code,
            title: title,
            threshold: 0.0,
            description: "",
            label: "",
            checksum: "",
            cost: 0.0,
            status: IsolationEntryStatus.requested
        )
    }
}
