import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual denial agreement is in its life cycle.
    enum ManualDenialAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual denial agreement. Its code is unique within a tenant.
    final class ManualDenialAgreement {
        var code: String
        var name: String
        var endsAt: Int
        var allergy: String
        var maximum: Double
        var title: String
        var refills: Int
        var updatedAt: Int
        var externalRef: String
        var rate: Double
        var ceiling: Double
        var status: ManualDenialAgreementStatus

        init(code: String, name: String, endsAt: Int, allergy: String, maximum: Double, title: String, refills: Int, updatedAt: Int, externalRef: String, rate: Double, ceiling: Double, status: ManualDenialAgreementStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.allergy = allergy
            self.maximum = maximum
            self.title = title
            self.refills = refills
            self.updatedAt = updatedAt
            self.externalRef = externalRef
            self.rate = rate
            self.ceiling = ceiling
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

        func canMoveTo(_ next: ManualDenialAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualDenialAgreementStatus.suspended
            case .pending:
                return next == ManualDenialAgreementStatus.closed
            case .active:
                return next == ManualDenialAgreementStatus.suspended || next == ManualDenialAgreementStatus.closed
            case .suspended:
                return next == ManualDenialAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualDenialAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual denial agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveValue() -> Double {
            return ((rate - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualDenialAgreement {
            return ManualDenialAgreement(
                code: code,
                name: name,
                endsAt: endsAt,
                allergy: allergy,
                maximum: maximum,
                title: title,
                refills: refills,
                updatedAt: updatedAt,
                externalRef: externalRef,
                rate: rate,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual denial agreement in status draft.
    static func newManualDenialAgreement(_ code: String, name: String) -> ManualDenialAgreement {
        return ManualDenialAgreement(
            code: code,
            name: name,
            endsAt: 0,
            allergy: "",
            maximum: 0.0,
            title: "",
            refills: 0,
            updatedAt: 0,
            externalRef: "",
            rate: 0.0,
            ceiling: 0.0,
            status: ManualDenialAgreementStatus.draft
        )
    }
}
