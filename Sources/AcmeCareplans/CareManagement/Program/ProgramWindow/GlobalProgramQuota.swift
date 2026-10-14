import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global program quota is in its life cycle.
    enum GlobalProgramQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A global program quota. Its code is unique within a tenant.
    final class GlobalProgramQuota {
        var code: String
        var title: String
        var segment: String
        var discount: Double
        var country: String
        var clinicianID: String
        var dosageMg: Double
        var windowDays: Int
        var status: GlobalProgramQuotaStatus

        init(code: String, title: String, segment: String, discount: Double, country: String, clinicianID: String, dosageMg: Double, windowDays: Int, status: GlobalProgramQuotaStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.discount = discount
            self.country = country
            self.clinicianID = clinicianID
            self.dosageMg = dosageMg
            self.windowDays = windowDays
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

        func canMoveTo(_ next: GlobalProgramQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalProgramQuotaStatus.approved || next == GlobalProgramQuotaStatus.withdrawn
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

        func moveTo(_ next: GlobalProgramQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global program quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global program quota") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(windowDays) + discount) * 100).rounded() / 100
        }

        func copyValue() -> GlobalProgramQuota {
            return GlobalProgramQuota(
                code: code,
                title: title,
                segment: segment,
                discount: discount,
                country: country,
                clinicianID: clinicianID,
                dosageMg: dosageMg,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global program quota in status proposed.
    static func newGlobalProgramQuota(_ code: String, title: String) -> GlobalProgramQuota {
        return GlobalProgramQuota(
            code: code,
            title: title,
            segment: "",
            discount: 0.0,
            country: "",
            clinicianID: "",
            dosageMg: 0.0,
            windowDays: 0,
            status: GlobalProgramQuotaStatus.proposed
        )
    }
}
