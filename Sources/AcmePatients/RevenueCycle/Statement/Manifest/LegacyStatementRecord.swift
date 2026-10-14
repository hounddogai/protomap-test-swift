import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy statement record is in its life cycle.
    enum LegacyStatementRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a legacy statement record and its current status.
    final class LegacyStatementRecord {
        var code: String
        var title: String
        var externalRef: String
        var phone: String
        var region: String
        var amount: Double
        var updatedAt: Int
        var status: LegacyStatementRecordStatus

        init(code: String, title: String, externalRef: String, phone: String, region: String, amount: Double, updatedAt: Int, status: LegacyStatementRecordStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.phone = phone
            self.region = region
            self.amount = amount
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyStatementRecordStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LegacyStatementRecordStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LegacyStatementRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy statement record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedTotal() -> Double {
            return (amount * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> LegacyStatementRecord {
            return LegacyStatementRecord(
                code: code,
                title: title,
                externalRef: externalRef,
                phone: phone,
                region: region,
                amount: amount,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy statement record in status idle.
    static func newLegacyStatementRecord(_ code: String, title: String) -> LegacyStatementRecord {
        return LegacyStatementRecord(
            code: code,
            title: title,
            externalRef: "",
            phone: "",
            region: "",
            amount: 0.0,
            updatedAt: 0,
            status: LegacyStatementRecordStatus.idle
        )
    }
}
