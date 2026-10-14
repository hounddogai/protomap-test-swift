import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol reservation is in its life cycle.
    enum CareProtocolReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care protocol reservation. Its code is unique within a tenant.
    final class CareProtocolReservation {
        var code: String
        var name: String
        var createdAt: Int
        var checksum: String
        var description: String
        var country: String
        var approved: Bool
        var weight: Double
        var diagnosisCode: String
        var locale: String
        var status: CareProtocolReservationStatus

        init(code: String, name: String, createdAt: Int, checksum: String, description: String, country: String, approved: Bool, weight: Double, diagnosisCode: String, locale: String, status: CareProtocolReservationStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.checksum = checksum
            self.description = description
            self.country = country
            self.approved = approved
            self.weight = weight
            self.diagnosisCode = diagnosisCode
            self.locale = locale
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

        func canMoveTo(_ next: CareProtocolReservationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CareProtocolReservationStatus.active || next == CareProtocolReservationStatus.closed
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: CareProtocolReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((Double(createdAt) - weight) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolReservation {
            return CareProtocolReservation(
                code: code,
                name: name,
                createdAt: createdAt,
                checksum: checksum,
                description: description,
                country: country,
                approved: approved,
                weight: weight,
                diagnosisCode: diagnosisCode,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a care protocol reservation in status draft.
    static func newCareProtocolReservation(_ code: String, name: String) -> CareProtocolReservation {
        return CareProtocolReservation(
            code: code,
            name: name,
            createdAt: 0,
            checksum: "",
            description: "",
            country: "",
            approved: false,
            weight: 0.0,
            diagnosisCode: "",
            locale: "",
            status: CareProtocolReservationStatus.draft
        )
    }
}
