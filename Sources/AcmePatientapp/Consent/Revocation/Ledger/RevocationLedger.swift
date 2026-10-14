import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation ledger is in its life cycle.
    enum RevocationLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A revocation ledger as the revocation team keeps it.
    final class RevocationLedger {
        var code: String
        var title: String
        var batchSize: Int
        var attributes: [String: String]
        var dosageMg: Double
        var copay: Double
        var updatedAt: Int
        var label: String
        var status: RevocationLedgerStatus

        init(code: String, title: String, batchSize: Int, attributes: [String: String], dosageMg: Double, copay: Double, updatedAt: Int, label: String, status: RevocationLedgerStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.attributes = attributes
            self.dosageMg = dosageMg
            self.copay = copay
            self.updatedAt = updatedAt
            self.label = label
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

        func canMoveTo(_ next: RevocationLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
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

        func moveTo(_ next: RevocationLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("revocation ledger") \(code)"
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

        func adjustedTotal() -> Double {
            return ((copay + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> RevocationLedger {
            return RevocationLedger(
                code: code,
                title: title,
                batchSize: batchSize,
                attributes: attributes,
                dosageMg: dosageMg,
                copay: copay,
                updatedAt: updatedAt,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a revocation ledger in status created.
    static func newRevocationLedger(_ code: String, title: String) -> RevocationLedger {
        return RevocationLedger(
            code: code,
            title: title,
            batchSize: 0,
            attributes: [:],
            dosageMg: 0.0,
            copay: 0.0,
            updatedAt: 0,
            label: "",
            status: RevocationLedgerStatus.created
        )
    }
}
