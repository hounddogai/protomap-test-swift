import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive study ledger is in its life cycle.
    enum AdaptiveStudyLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive study ledger. Its code is unique within a tenant.
    final class AdaptiveStudyLedger {
        var code: String
        var name: String
        var unit: String
        var attempts: Int
        var maximum: Double
        var score: Double
        var region: String
        var payer: String
        var endsAt: Int
        var status: AdaptiveStudyLedgerStatus

        init(code: String, name: String, unit: String, attempts: Int, maximum: Double, score: Double, region: String, payer: String, endsAt: Int, status: AdaptiveStudyLedgerStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.attempts = attempts
            self.maximum = maximum
            self.score = score
            self.region = region
            self.payer = payer
            self.endsAt = endsAt
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

        func canMoveTo(_ next: AdaptiveStudyLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AdaptiveStudyLedgerStatus.active || next == AdaptiveStudyLedgerStatus.suspended
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AdaptiveStudyLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive study ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveValue() -> Double {
            return (Double(attempts) * maximum * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveStudyLedger {
            return AdaptiveStudyLedger(
                code: code,
                name: name,
                unit: unit,
                attempts: attempts,
                maximum: maximum,
                score: score,
                region: region,
                payer: payer,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive study ledger in status draft.
    static func newAdaptiveStudyLedger(_ code: String, name: String) -> AdaptiveStudyLedger {
        return AdaptiveStudyLedger(
            code: code,
            name: name,
            unit: "",
            attempts: 0,
            maximum: 0.0,
            score: 0.0,
            region: "",
            payer: "",
            endsAt: 0,
            status: AdaptiveStudyLedgerStatus.draft
        )
    }
}
