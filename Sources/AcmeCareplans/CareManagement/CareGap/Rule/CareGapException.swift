import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap exception is in its life cycle.
    enum CareGapExceptionStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care gap exception. Its code is unique within a tenant.
    final class CareGapException {
        var code: String
        var title: String
        var description: String
        var allergy: String
        var startsAt: Int
        var version: Int
        var phone: String
        var diagnosisCode: String
        var source: String
        var cost: Double
        var status: CareGapExceptionStatus

        init(code: String, title: String, description: String, allergy: String, startsAt: Int, version: Int, phone: String, diagnosisCode: String, source: String, cost: Double, status: CareGapExceptionStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.allergy = allergy
            self.startsAt = startsAt
            self.version = version
            self.phone = phone
            self.diagnosisCode = diagnosisCode
            self.source = source
            self.cost = cost
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

        func canMoveTo(_ next: CareGapExceptionStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CareGapExceptionStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CareGapExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("care gap exception") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(startsAt) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapException {
            return CareGapException(
                code: code,
                title: title,
                description: description,
                allergy: allergy,
                startsAt: startsAt,
                version: version,
                phone: phone,
                diagnosisCode: diagnosisCode,
                source: source,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a care gap exception in status draft.
    static func newCareGapException(_ code: String, title: String) -> CareGapException {
        return CareGapException(
            code: code,
            title: title,
            description: "",
            allergy: "",
            startsAt: 0,
            version: 0,
            phone: "",
            diagnosisCode: "",
            source: "",
            cost: 0.0,
            status: CareGapExceptionStatus.draft
        )
    }
}
