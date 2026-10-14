import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim rollup is in its life cycle.
    enum ClaimRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A claim rollup. Its code is unique within a tenant.
    final class ClaimRollup {
        var code: String
        var name: String
        var ceiling: Double
        var segment: String
        var patientRef: String
        var discount: Double
        var encounterID: String
        var updatedAt: Int
        var payer: String
        var status: ClaimRollupStatus

        init(code: String, name: String, ceiling: Double, segment: String, patientRef: String, discount: Double, encounterID: String, updatedAt: Int, payer: String, status: ClaimRollupStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.segment = segment
            self.patientRef = patientRef
            self.discount = discount
            self.encounterID = encounterID
            self.updatedAt = updatedAt
            self.payer = payer
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

        func canMoveTo(_ next: ClaimRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == ClaimRollupStatus.active || next == ClaimRollupStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ClaimRollupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return ((discount + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimRollup {
            return ClaimRollup(
                code: code,
                name: name,
                ceiling: ceiling,
                segment: segment,
                patientRef: patientRef,
                discount: discount,
                encounterID: encounterID,
                updatedAt: updatedAt,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a claim rollup in status draft.
    static func newClaimRollup(_ code: String, name: String) -> ClaimRollup {
        return ClaimRollup(
            code: code,
            name: name,
            ceiling: 0.0,
            segment: "",
            patientRef: "",
            discount: 0.0,
            encounterID: "",
            updatedAt: 0,
            payer: "",
            status: ClaimRollupStatus.draft
        )
    }
}
