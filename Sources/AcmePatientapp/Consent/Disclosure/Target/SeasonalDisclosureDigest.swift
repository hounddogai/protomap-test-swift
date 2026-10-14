import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal disclosure digest is in its life cycle.
    enum SeasonalDisclosureDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One seasonal disclosure digest, with what the planners need to act on it.
    final class SeasonalDisclosureDigest {
        var code: String
        var title: String
        var phone: String
        var copay: Double
        var durationMinutes: Int
        var updatedAt: Int
        var budget: Double
        var bed: String
        var clinicianID: String
        var status: SeasonalDisclosureDigestStatus

        init(code: String, title: String, phone: String, copay: Double, durationMinutes: Int, updatedAt: Int, budget: Double, bed: String, clinicianID: String, status: SeasonalDisclosureDigestStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.updatedAt = updatedAt
            self.budget = budget
            self.bed = bed
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: SeasonalDisclosureDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalDisclosureDigestStatus.approved || next == SeasonalDisclosureDigestStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: SeasonalDisclosureDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal disclosure digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal disclosure digest") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(durationMinutes) + copay) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalDisclosureDigest {
            return SeasonalDisclosureDigest(
                code: code,
                title: title,
                phone: phone,
                copay: copay,
                durationMinutes: durationMinutes,
                updatedAt: updatedAt,
                budget: budget,
                bed: bed,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal disclosure digest in status proposed.
    static func newSeasonalDisclosureDigest(_ code: String, title: String) -> SeasonalDisclosureDigest {
        return SeasonalDisclosureDigest(
            code: code,
            title: title,
            phone: "",
            copay: 0.0,
            durationMinutes: 0,
            updatedAt: 0,
            budget: 0.0,
            bed: "",
            clinicianID: "",
            status: SeasonalDisclosureDigestStatus.proposed
        )
    }
}
