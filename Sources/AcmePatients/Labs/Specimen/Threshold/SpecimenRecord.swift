import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen record is in its life cycle.
    enum SpecimenRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A specimen record as the specimen team keeps it.
    final class SpecimenRecord {
        var code: String
        var name: String
        var version: Int
        var durationMinutes: Int
        var currency: String
        var rate: Double
        var status: SpecimenRecordStatus

        init(code: String, name: String, version: Int, durationMinutes: Int, currency: String, rate: Double, status: SpecimenRecordStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.durationMinutes = durationMinutes
            self.currency = currency
            self.rate = rate
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

        func canMoveTo(_ next: SpecimenRecordStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SpecimenRecordStatus.closed
            case .suspended:
                return next == SpecimenRecordStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("specimen record") \(code)"
        }

        func effectiveTotal() -> Double {
            return (Double(durationMinutes) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenRecord {
            return SpecimenRecord(
                code: code,
                name: name,
                version: version,
                durationMinutes: durationMinutes,
                currency: currency,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a specimen record in status draft.
    static func newSpecimenRecord(_ code: String, name: String) -> SpecimenRecord {
        return SpecimenRecord(
            code: code,
            name: name,
            version: 0,
            durationMinutes: 0,
            currency: "",
            rate: 0.0,
            status: SpecimenRecordStatus.draft
        )
    }
}
