import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default read ledger is in its life cycle.
    enum DefaultReadLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One default read ledger, with what the planners need to act on it.
    final class DefaultReadLedger {
        var code: String
        var title: String
        var label: String
        var region: String
        var attributes: [String: String]
        var approved: Bool
        var ratio: Double
        var graceDays: Int
        var windowDays: Int
        var status: DefaultReadLedgerStatus

        init(code: String, title: String, label: String, region: String, attributes: [String: String], approved: Bool, ratio: Double, graceDays: Int, windowDays: Int, status: DefaultReadLedgerStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.region = region
            self.attributes = attributes
            self.approved = approved
            self.ratio = ratio
            self.graceDays = graceDays
            self.windowDays = windowDays
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

        func canMoveTo(_ next: DefaultReadLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultReadLedgerStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DefaultReadLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultReadLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default read ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netTotal() -> Double {
            return ((ratio + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultReadLedger {
            return DefaultReadLedger(
                code: code,
                title: title,
                label: label,
                region: region,
                attributes: attributes,
                approved: approved,
                ratio: ratio,
                graceDays: graceDays,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a default read ledger in status created.
    static func newDefaultReadLedger(_ code: String, title: String) -> DefaultReadLedger {
        return DefaultReadLedger(
            code: code,
            title: title,
            label: "",
            region: "",
            attributes: [:],
            approved: false,
            ratio: 0.0,
            graceDays: 0,
            windowDays: 0,
            status: DefaultReadLedgerStatus.created
        )
    }
}
