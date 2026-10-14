import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual statement ledger is in its life cycle.
    enum ManualStatementLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual statement ledger. Its code is unique within a tenant.
    final class ManualStatementLedger {
        var code: String
        var name: String
        var ceiling: Double
        var windowDays: Int
        var graceDays: Int
        var contactEmail: String
        var margin: Double
        var batchSize: Int
        var specialty: String
        var country: String
        var version: Int
        var status: ManualStatementLedgerStatus

        init(code: String, name: String, ceiling: Double, windowDays: Int, graceDays: Int, contactEmail: String, margin: Double, batchSize: Int, specialty: String, country: String, version: Int, status: ManualStatementLedgerStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.windowDays = windowDays
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.margin = margin
            self.batchSize = batchSize
            self.specialty = specialty
            self.country = country
            self.version = version
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

        func canMoveTo(_ next: ManualStatementLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ManualStatementLedgerStatus.retired
            case .published:
                return next == ManualStatementLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualStatementLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual statement ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return (Double(graceDays) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> ManualStatementLedger {
            return ManualStatementLedger(
                code: code,
                name: name,
                ceiling: ceiling,
                windowDays: windowDays,
                graceDays: graceDays,
                contactEmail: contactEmail,
                margin: margin,
                batchSize: batchSize,
                specialty: specialty,
                country: country,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual statement ledger in status created.
    static func newManualStatementLedger(_ code: String, name: String) -> ManualStatementLedger {
        return ManualStatementLedger(
            code: code,
            name: name,
            ceiling: 0.0,
            windowDays: 0,
            graceDays: 0,
            contactEmail: "",
            margin: 0.0,
            batchSize: 0,
            specialty: "",
            country: "",
            version: 0,
            status: ManualStatementLedgerStatus.created
        )
    }
}
