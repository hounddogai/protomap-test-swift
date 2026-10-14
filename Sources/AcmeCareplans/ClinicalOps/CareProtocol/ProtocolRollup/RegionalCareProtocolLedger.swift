import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional care protocol ledger is in its life cycle.
    enum RegionalCareProtocolLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional care protocol ledger as the care protocol team keeps it.
    final class RegionalCareProtocolLedger {
        var code: String
        var name: String
        var region: String
        var threshold: Double
        var channel: String
        var retries: Int
        var approved: Bool
        var visitMinutes: Int
        var checksum: String
        var payer: String
        var visible: Bool
        var status: RegionalCareProtocolLedgerStatus

        init(code: String, name: String, region: String, threshold: Double, channel: String, retries: Int, approved: Bool, visitMinutes: Int, checksum: String, payer: String, visible: Bool, status: RegionalCareProtocolLedgerStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.threshold = threshold
            self.channel = channel
            self.retries = retries
            self.approved = approved
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.payer = payer
            self.visible = visible
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

        func canMoveTo(_ next: RegionalCareProtocolLedgerStatus) -> Bool {
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
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RegionalCareProtocolLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalCareProtocolLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care protocol ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedValue() -> Double {
            return ((threshold - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCareProtocolLedger {
            return RegionalCareProtocolLedger(
                code: code,
                name: name,
                region: region,
                threshold: threshold,
                channel: channel,
                retries: retries,
                approved: approved,
                visitMinutes: visitMinutes,
                checksum: checksum,
                payer: payer,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional care protocol ledger in status created.
    static func newRegionalCareProtocolLedger(_ code: String, name: String) -> RegionalCareProtocolLedger {
        return RegionalCareProtocolLedger(
            code: code,
            name: name,
            region: "",
            threshold: 0.0,
            channel: "",
            retries: 0,
            approved: false,
            visitMinutes: 0,
            checksum: "",
            payer: "",
            visible: false,
            status: RegionalCareProtocolLedgerStatus.created
        )
    }
}
