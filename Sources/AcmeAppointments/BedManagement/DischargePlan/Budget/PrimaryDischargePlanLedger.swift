import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary discharge plan ledger is in its life cycle.
    enum PrimaryDischargePlanLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary discharge plan ledger. Its code is unique within a tenant.
    final class PrimaryDischargePlanLedger {
        var code: String
        var title: String
        var copay: Double
        var ward: String
        var version: Int
        var floorValue: Double
        var expiresAt: Int
        var checksum: String
        var segment: String
        var weight: Double
        var acuity: Int
        var status: PrimaryDischargePlanLedgerStatus

        init(code: String, title: String, copay: Double, ward: String, version: Int, floorValue: Double, expiresAt: Int, checksum: String, segment: String, weight: Double, acuity: Int, status: PrimaryDischargePlanLedgerStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.ward = ward
            self.version = version
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.checksum = checksum
            self.segment = segment
            self.weight = weight
            self.acuity = acuity
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

        func canMoveTo(_ next: PrimaryDischargePlanLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PrimaryDischargePlanLedgerStatus.reopened
            case .resolved:
                return next == PrimaryDischargePlanLedgerStatus.reopened || next == PrimaryDischargePlanLedgerStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PrimaryDischargePlanLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary discharge plan ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return ((copay - weight) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDischargePlanLedger {
            return PrimaryDischargePlanLedger(
                code: code,
                title: title,
                copay: copay,
                ward: ward,
                version: version,
                floorValue: floorValue,
                expiresAt: expiresAt,
                checksum: checksum,
                segment: segment,
                weight: weight,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a primary discharge plan ledger in status open.
    static func newPrimaryDischargePlanLedger(_ code: String, title: String) -> PrimaryDischargePlanLedger {
        return PrimaryDischargePlanLedger(
            code: code,
            title: title,
            copay: 0.0,
            ward: "",
            version: 0,
            floorValue: 0.0,
            expiresAt: 0,
            checksum: "",
            segment: "",
            weight: 0.0,
            acuity: 0,
            status: PrimaryDischargePlanLedgerStatus.`open`
        )
    }
}
