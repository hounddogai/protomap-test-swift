import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality ledger is in its life cycle.
    enum ModalityLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A modality ledger as the modality team keeps it.
    final class ModalityLedger {
        var code: String
        var name: String
        var durationMinutes: Int
        var expiresAt: Int
        var tags: [String]
        var channel: String
        var margin: Double
        var description: String
        var payer: String
        var status: ModalityLedgerStatus

        init(code: String, name: String, durationMinutes: Int, expiresAt: Int, tags: [String], channel: String, margin: Double, description: String, payer: String, status: ModalityLedgerStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.tags = tags
            self.channel = channel
            self.margin = margin
            self.description = description
            self.payer = payer
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

        func canMoveTo(_ next: ModalityLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
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

        func moveTo(_ next: ModalityLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return ((Double(expiresAt) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityLedger {
            return ModalityLedger(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                tags: tags,
                channel: channel,
                margin: margin,
                description: description,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a modality ledger in status created.
    static func newModalityLedger(_ code: String, name: String) -> ModalityLedger {
        return ModalityLedger(
            code: code,
            name: name,
            durationMinutes: 0,
            expiresAt: 0,
            tags: [],
            channel: "",
            margin: 0.0,
            description: "",
            payer: "",
            status: ModalityLedgerStatus.created
        )
    }
}
