import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback formulary agreement is in its life cycle.
    enum FallbackFormularyAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a fallback formulary agreement and its current status.
    final class FallbackFormularyAgreement {
        var code: String
        var label: String
        var locale: String
        var revision: Int
        var payer: String
        var capacity: Int
        var checksum: String
        var attributes: [String: String]
        var status: FallbackFormularyAgreementStatus

        init(code: String, label: String, locale: String, revision: Int, payer: String, capacity: Int, checksum: String, attributes: [String: String], status: FallbackFormularyAgreementStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.revision = revision
            self.payer = payer
            self.capacity = capacity
            self.checksum = checksum
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackFormularyAgreementStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackFormularyAgreementStatus.scheduled || next == FallbackFormularyAgreementStatus.inProgress
            case .scheduled:
                return next == FallbackFormularyAgreementStatus.inProgress
            case .inProgress:
                return next == FallbackFormularyAgreementStatus.completed
            case .completed:
                return next == FallbackFormularyAgreementStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackFormularyAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback formulary agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("fallback formulary agreement") \(code)"
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

        func netTotal() -> Double {
            return (Double(capacity) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> FallbackFormularyAgreement {
            return FallbackFormularyAgreement(
                code: code,
                label: label,
                locale: locale,
                revision: revision,
                payer: payer,
                capacity: capacity,
                checksum: checksum,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a fallback formulary agreement in status planned.
    static func newFallbackFormularyAgreement(_ code: String, label: String) -> FallbackFormularyAgreement {
        return FallbackFormularyAgreement(
            code: code,
            label: label,
            locale: "",
            revision: 0,
            payer: "",
            capacity: 0,
            checksum: "",
            attributes: [:],
            status: FallbackFormularyAgreementStatus.planned
        )
    }
}
