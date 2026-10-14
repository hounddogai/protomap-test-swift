import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal slot record is in its life cycle.
    enum SeasonalSlotRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One seasonal slot record, with what the planners need to act on it.
    final class SeasonalSlotRecord {
        var code: String
        var name: String
        var rate: Double
        var updatedAt: Int
        var ward: String
        var locale: String
        var ceiling: Double
        var status: SeasonalSlotRecordStatus

        init(code: String, name: String, rate: Double, updatedAt: Int, ward: String, locale: String, ceiling: Double, status: SeasonalSlotRecordStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.updatedAt = updatedAt
            self.ward = ward
            self.locale = locale
            self.ceiling = ceiling
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

        func canMoveTo(_ next: SeasonalSlotRecordStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: SeasonalSlotRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal slot record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal slot record") \(code)"
        }

        func weightedValue() -> Double {
            return (ceiling * rate * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSlotRecord {
            return SeasonalSlotRecord(
                code: code,
                name: name,
                rate: rate,
                updatedAt: updatedAt,
                ward: ward,
                locale: locale,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a seasonal slot record in status draft.
    static func newSeasonalSlotRecord(_ code: String, name: String) -> SeasonalSlotRecord {
        return SeasonalSlotRecord(
            code: code,
            name: name,
            rate: 0.0,
            updatedAt: 0,
            ward: "",
            locale: "",
            ceiling: 0.0,
            status: SeasonalSlotRecordStatus.draft
        )
    }
}
