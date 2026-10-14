import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form reservation is in its life cycle.
    enum ConsentFormReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a consent form reservation and its current status.
    final class ConsentFormReservation {
        var code: String
        var name: String
        var approved: Bool
        var title: String
        var payer: String
        var notes: String
        var externalRef: String
        var visitMinutes: Int
        var attributes: [String: String]
        var updatedAt: Int
        var status: ConsentFormReservationStatus

        init(code: String, name: String, approved: Bool, title: String, payer: String, notes: String, externalRef: String, visitMinutes: Int, attributes: [String: String], updatedAt: Int, status: ConsentFormReservationStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.title = title
            self.payer = payer
            self.notes = notes
            self.externalRef = externalRef
            self.visitMinutes = visitMinutes
            self.attributes = attributes
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ConsentFormReservationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ConsentFormReservationStatus.rejected || next == ConsentFormReservationStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ConsentFormReservationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func netValue() -> Double {
            return (Double(updatedAt) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormReservation {
            return ConsentFormReservation(
                code: code,
                name: name,
                approved: approved,
                title: title,
                payer: payer,
                notes: notes,
                externalRef: externalRef,
                visitMinutes: visitMinutes,
                attributes: attributes,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a consent form reservation in status proposed.
    static func newConsentFormReservation(_ code: String, name: String) -> ConsentFormReservation {
        return ConsentFormReservation(
            code: code,
            name: name,
            approved: false,
            title: "",
            payer: "",
            notes: "",
            externalRef: "",
            visitMinutes: 0,
            attributes: [:],
            updatedAt: 0,
            status: ConsentFormReservationStatus.proposed
        )
    }
}
