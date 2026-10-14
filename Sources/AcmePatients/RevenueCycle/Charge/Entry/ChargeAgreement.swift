import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge agreement is in its life cycle.
    enum ChargeAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One charge agreement, with what the planners need to act on it.
    final class ChargeAgreement {
        var code: String
        var name: String
        var version: Int
        var region: String
        var quantity: Int
        var status: ChargeAgreementStatus

        init(code: String, name: String, version: Int, region: String, quantity: Int, status: ChargeAgreementStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.region = region
            self.quantity = quantity
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

        func canMoveTo(_ next: ChargeAgreementStatus) -> Bool {
            switch status {
            case .created:
                return next == ChargeAgreementStatus.retired
            case .validated:
                return next == ChargeAgreementStatus.published || next == ChargeAgreementStatus.retired
            case .published:
                return next == ChargeAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("charge agreement") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(version) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeAgreement {
            return ChargeAgreement(
                code: code,
                name: name,
                version: version,
                region: region,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a charge agreement in status created.
    static func newChargeAgreement(_ code: String, name: String) -> ChargeAgreement {
        return ChargeAgreement(
            code: code,
            name: name,
            version: 0,
            region: "",
            quantity: 0,
            status: ChargeAgreementStatus.created
        )
    }
}
