import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy remittance rule is in its life cycle.
    enum LegacyRemittanceRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One legacy remittance rule, with what the planners need to act on it.
    final class LegacyRemittanceRule {
        var code: String
        var name: String
        var clinicianID: String
        var specialty: String
        var quantity: Int
        var expiresAt: Int
        var limit: Int
        var acuity: Int
        var tags: [String]
        var batchSize: Int
        var dosageMg: Double
        var status: LegacyRemittanceRuleStatus

        init(code: String, name: String, clinicianID: String, specialty: String, quantity: Int, expiresAt: Int, limit: Int, acuity: Int, tags: [String], batchSize: Int, dosageMg: Double, status: LegacyRemittanceRuleStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.quantity = quantity
            self.expiresAt = expiresAt
            self.limit = limit
            self.acuity = acuity
            self.tags = tags
            self.batchSize = batchSize
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyRemittanceRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyRemittanceRuleStatus.failed
            case .queued:
                return next == LegacyRemittanceRuleStatus.failed
            case .running:
                return next == LegacyRemittanceRuleStatus.done || next == LegacyRemittanceRuleStatus.failed
            case .done:
                return next == LegacyRemittanceRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyRemittanceRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy remittance rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return ((dosageMg + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyRemittanceRule {
            return LegacyRemittanceRule(
                code: code,
                name: name,
                clinicianID: clinicianID,
                specialty: specialty,
                quantity: quantity,
                expiresAt: expiresAt,
                limit: limit,
                acuity: acuity,
                tags: tags,
                batchSize: batchSize,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy remittance rule in status new.
    static func newLegacyRemittanceRule(_ code: String, name: String) -> LegacyRemittanceRule {
        return LegacyRemittanceRule(
            code: code,
            name: name,
            clinicianID: "",
            specialty: "",
            quantity: 0,
            expiresAt: 0,
            limit: 0,
            acuity: 0,
            tags: [],
            batchSize: 0,
            dosageMg: 0.0,
            status: LegacyRemittanceRuleStatus.new
        )
    }
}
