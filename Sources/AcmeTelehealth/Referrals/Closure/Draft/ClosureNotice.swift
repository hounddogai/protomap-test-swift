import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure notice is in its life cycle.
    enum ClosureNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a closure notice and its current status.
    final class ClosureNotice {
        var code: String
        var name: String
        var bed: String
        var payer: String
        var refills: Int
        var ward: String
        var procedureCode: String
        var attributes: [String: String]
        var label: String
        var active: Bool
        var status: ClosureNoticeStatus

        init(code: String, name: String, bed: String, payer: String, refills: Int, ward: String, procedureCode: String, attributes: [String: String], label: String, active: Bool, status: ClosureNoticeStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.payer = payer
            self.refills = refills
            self.ward = ward
            self.procedureCode = procedureCode
            self.attributes = attributes
            self.label = label
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClosureNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ClosureNoticeStatus.rejected
            case .approved:
                return next == ClosureNoticeStatus.withdrawn
            case .rejected:
                return next == ClosureNoticeStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("closure notice") \(code)"
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

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> ClosureNotice {
            return ClosureNotice(
                code: code,
                name: name,
                bed: bed,
                payer: payer,
                refills: refills,
                ward: ward,
                procedureCode: procedureCode,
                attributes: attributes,
                label: label,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a closure notice in status proposed.
    static func newClosureNotice(_ code: String, name: String) -> ClosureNotice {
        return ClosureNotice(
            code: code,
            name: name,
            bed: "",
            payer: "",
            refills: 0,
            ward: "",
            procedureCode: "",
            attributes: [:],
            label: "",
            active: false,
            status: ClosureNoticeStatus.proposed
        )
    }
}
