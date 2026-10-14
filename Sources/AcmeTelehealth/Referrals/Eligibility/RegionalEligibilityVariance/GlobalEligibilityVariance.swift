import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global eligibility variance is in its life cycle.
    enum GlobalEligibilityVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global eligibility variance, with what the planners need to act on it.
    final class GlobalEligibilityVariance {
        var code: String
        var title: String
        var floorValue: Double
        var refills: Int
        var sequence: Int
        var clinicianID: String
        var windowDays: Int
        var margin: Double
        var pinned: Bool
        var retries: Int
        var approved: Bool
        var status: GlobalEligibilityVarianceStatus

        init(code: String, title: String, floorValue: Double, refills: Int, sequence: Int, clinicianID: String, windowDays: Int, margin: Double, pinned: Bool, retries: Int, approved: Bool, status: GlobalEligibilityVarianceStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.refills = refills
            self.sequence = sequence
            self.clinicianID = clinicianID
            self.windowDays = windowDays
            self.margin = margin
            self.pinned = pinned
            self.retries = retries
            self.approved = approved
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

        func canMoveTo(_ next: GlobalEligibilityVarianceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalEligibilityVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global eligibility variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global eligibility variance") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(windowDays) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalEligibilityVariance {
            return GlobalEligibilityVariance(
                code: code,
                title: title,
                floorValue: floorValue,
                refills: refills,
                sequence: sequence,
                clinicianID: clinicianID,
                windowDays: windowDays,
                margin: margin,
                pinned: pinned,
                retries: retries,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global eligibility variance in status created.
    static func newGlobalEligibilityVariance(_ code: String, title: String) -> GlobalEligibilityVariance {
        return GlobalEligibilityVariance(
            code: code,
            title: title,
            floorValue: 0.0,
            refills: 0,
            sequence: 0,
            clinicianID: "",
            windowDays: 0,
            margin: 0.0,
            pinned: false,
            retries: 0,
            approved: false,
            status: GlobalEligibilityVarianceStatus.created
        )
    }
}
