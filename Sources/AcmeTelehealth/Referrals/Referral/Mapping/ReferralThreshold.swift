import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral threshold is in its life cycle.
    enum ReferralThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A referral threshold. Its code is unique within a tenant.
    final class ReferralThreshold {
        var code: String
        var name: String
        var revision: Int
        var margin: Double
        var approved: Bool
        var tags: [String]
        var specialty: String
        var windowDays: Int
        var floorValue: Double
        var ceiling: Double
        var checksum: String
        var status: ReferralThresholdStatus

        init(code: String, name: String, revision: Int, margin: Double, approved: Bool, tags: [String], specialty: String, windowDays: Int, floorValue: Double, ceiling: Double, checksum: String, status: ReferralThresholdStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.margin = margin
            self.approved = approved
            self.tags = tags
            self.specialty = specialty
            self.windowDays = windowDays
            self.floorValue = floorValue
            self.ceiling = ceiling
            self.checksum = checksum
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

        func canMoveTo(_ next: ReferralThresholdStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ReferralThresholdStatus.draining
            case .ready:
                return next == ReferralThresholdStatus.draining
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

        func moveTo(_ next: ReferralThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("referral threshold") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((margin - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralThreshold {
            return ReferralThreshold(
                code: code,
                name: name,
                revision: revision,
                margin: margin,
                approved: approved,
                tags: tags,
                specialty: specialty,
                windowDays: windowDays,
                floorValue: floorValue,
                ceiling: ceiling,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral threshold in status idle.
    static func newReferralThreshold(_ code: String, name: String) -> ReferralThreshold {
        return ReferralThreshold(
            code: code,
            name: name,
            revision: 0,
            margin: 0.0,
            approved: false,
            tags: [],
            specialty: "",
            windowDays: 0,
            floorValue: 0.0,
            ceiling: 0.0,
            checksum: "",
            status: ReferralThresholdStatus.idle
        )
    }
}
