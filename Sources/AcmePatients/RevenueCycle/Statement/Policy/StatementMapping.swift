import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement mapping is in its life cycle.
    enum StatementMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A statement mapping. Its code is unique within a tenant.
    final class StatementMapping {
        var code: String
        var title: String
        var revision: Int
        var acuity: Int
        var procedureCode: String
        var specialty: String
        var ward: String
        var minimum: Double
        var ceiling: Double
        var currency: String
        var status: StatementMappingStatus

        init(code: String, title: String, revision: Int, acuity: Int, procedureCode: String, specialty: String, ward: String, minimum: Double, ceiling: Double, currency: String, status: StatementMappingStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.acuity = acuity
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.ward = ward
            self.minimum = minimum
            self.ceiling = ceiling
            self.currency = currency
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

        func canMoveTo(_ next: StatementMappingStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StatementMappingStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: StatementMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return ((ceiling - minimum) * 100).rounded() / 100
        }

        func copyValue() -> StatementMapping {
            return StatementMapping(
                code: code,
                title: title,
                revision: revision,
                acuity: acuity,
                procedureCode: procedureCode,
                specialty: specialty,
                ward: ward,
                minimum: minimum,
                ceiling: ceiling,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a statement mapping in status created.
    static func newStatementMapping(_ code: String, title: String) -> StatementMapping {
        return StatementMapping(
            code: code,
            title: title,
            revision: 0,
            acuity: 0,
            procedureCode: "",
            specialty: "",
            ward: "",
            minimum: 0.0,
            ceiling: 0.0,
            currency: "",
            status: StatementMappingStatus.created
        )
    }
}
