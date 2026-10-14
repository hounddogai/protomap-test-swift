import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional referral rollup is in its life cycle.
    enum RegionalReferralRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A regional referral rollup as the referral team keeps it.
    final class RegionalReferralRollup {
        var code: String
        var title: String
        var patientRef: String
        var notes: String
        var country: String
        var unit: String
        var procedureCode: String
        var updatedAt: Int
        var segment: String
        var status: RegionalReferralRollupStatus

        init(code: String, title: String, patientRef: String, notes: String, country: String, unit: String, procedureCode: String, updatedAt: Int, segment: String, status: RegionalReferralRollupStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.notes = notes
            self.country = country
            self.unit = unit
            self.procedureCode = procedureCode
            self.updatedAt = updatedAt
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalReferralRollupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RegionalReferralRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional referral rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> RegionalReferralRollup {
            return RegionalReferralRollup(
                code: code,
                title: title,
                patientRef: patientRef,
                notes: notes,
                country: country,
                unit: unit,
                procedureCode: procedureCode,
                updatedAt: updatedAt,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional referral rollup in status idle.
    static func newRegionalReferralRollup(_ code: String, title: String) -> RegionalReferralRollup {
        return RegionalReferralRollup(
            code: code,
            title: title,
            patientRef: "",
            notes: "",
            country: "",
            unit: "",
            procedureCode: "",
            updatedAt: 0,
            segment: "",
            status: RegionalReferralRollupStatus.idle
        )
    }
}
