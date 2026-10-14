import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board quota is in its life cycle.
    enum BedBoardQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A bed board quota. Its code is unique within a tenant.
    final class BedBoardQuota {
        var code: String
        var title: String
        var timezone: String
        var weight: Double
        var acuity: Int
        var notes: String
        var budget: Double
        var status: BedBoardQuotaStatus

        init(code: String, title: String, timezone: String, weight: Double, acuity: Int, notes: String, budget: Double, status: BedBoardQuotaStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.weight = weight
            self.acuity = acuity
            self.notes = notes
            self.budget = budget
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

        func canMoveTo(_ next: BedBoardQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == BedBoardQuotaStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: BedBoardQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedVolume() -> Double {
            return ((weight + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardQuota {
            return BedBoardQuota(
                code: code,
                title: title,
                timezone: timezone,
                weight: weight,
                acuity: acuity,
                notes: notes,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a bed board quota in status created.
    static func newBedBoardQuota(_ code: String, title: String) -> BedBoardQuota {
        return BedBoardQuota(
            code: code,
            title: title,
            timezone: "",
            weight: 0.0,
            acuity: 0,
            notes: "",
            budget: 0.0,
            status: BedBoardQuotaStatus.created
        )
    }
}
