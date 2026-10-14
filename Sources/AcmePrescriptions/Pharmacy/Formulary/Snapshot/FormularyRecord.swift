import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary record is in its life cycle.
    enum FormularyRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a formulary record and its current status.
    final class FormularyRecord {
        var code: String
        var name: String
        var weight: Double
        var archived: Bool
        var rate: Double
        var allergy: String
        var source: String
        var durationMinutes: Int
        var externalRef: String
        var expiresAt: Int
        var status: FormularyRecordStatus

        init(code: String, name: String, weight: Double, archived: Bool, rate: Double, allergy: String, source: String, durationMinutes: Int, externalRef: String, expiresAt: Int, status: FormularyRecordStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.archived = archived
            self.rate = rate
            self.allergy = allergy
            self.source = source
            self.durationMinutes = durationMinutes
            self.externalRef = externalRef
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: FormularyRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FormularyRecordStatus.rejected || next == FormularyRecordStatus.withdrawn
            case .rejected:
                return next == FormularyRecordStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("formulary record") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(durationMinutes) - rate) * 100).rounded() / 100
        }

        func copyValue() -> FormularyRecord {
            return FormularyRecord(
                code: code,
                name: name,
                weight: weight,
                archived: archived,
                rate: rate,
                allergy: allergy,
                source: source,
                durationMinutes: durationMinutes,
                externalRef: externalRef,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a formulary record in status proposed.
    static func newFormularyRecord(_ code: String, name: String) -> FormularyRecord {
        return FormularyRecord(
            code: code,
            name: name,
            weight: 0.0,
            archived: false,
            rate: 0.0,
            allergy: "",
            source: "",
            durationMinutes: 0,
            externalRef: "",
            expiresAt: 0,
            status: FormularyRecordStatus.proposed
        )
    }
}
