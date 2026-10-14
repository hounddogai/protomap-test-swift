import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding manifest is in its life cycle.
    enum RoundingManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rounding manifest as the rounding team keeps it.
    final class RoundingManifest {
        var code: String
        var name: String
        var approved: Bool
        var reviewer: String
        var phone: String
        var bed: String
        var attempts: Int
        var retries: Int
        var amount: Double
        var procedureCode: String
        var status: RoundingManifestStatus

        init(code: String, name: String, approved: Bool, reviewer: String, phone: String, bed: String, attempts: Int, retries: Int, amount: Double, procedureCode: String, status: RoundingManifestStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.reviewer = reviewer
            self.phone = phone
            self.bed = bed
            self.attempts = attempts
            self.retries = retries
            self.amount = amount
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: RoundingManifestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RoundingManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rounding manifest") \(code)"
        }

        func weightedVolume() -> Double {
            return (Double(retries) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> RoundingManifest {
            return RoundingManifest(
                code: code,
                name: name,
                approved: approved,
                reviewer: reviewer,
                phone: phone,
                bed: bed,
                attempts: attempts,
                retries: retries,
                amount: amount,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding manifest in status proposed.
    static func newRoundingManifest(_ code: String, name: String) -> RoundingManifest {
        return RoundingManifest(
            code: code,
            name: name,
            approved: false,
            reviewer: "",
            phone: "",
            bed: "",
            attempts: 0,
            retries: 0,
            amount: 0.0,
            procedureCode: "",
            status: RoundingManifestStatus.proposed
        )
    }
}
