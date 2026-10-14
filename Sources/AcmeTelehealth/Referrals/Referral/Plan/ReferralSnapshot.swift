import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral snapshot is in its life cycle.
    enum ReferralSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a referral snapshot and its current status.
    final class ReferralSnapshot {
        var code: String
        var title: String
        var approved: Bool
        var region: String
        var windowDays: Int
        var tags: [String]
        var unit: String
        var sequence: Int
        var status: ReferralSnapshotStatus

        init(code: String, title: String, approved: Bool, region: String, windowDays: Int, tags: [String], unit: String, sequence: Int, status: ReferralSnapshotStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.region = region
            self.windowDays = windowDays
            self.tags = tags
            self.unit = unit
            self.sequence = sequence
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

        func canMoveTo(_ next: ReferralSnapshotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ReferralSnapshotStatus.retired
            case .published:
                return next == ReferralSnapshotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((Double(windowDays) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralSnapshot {
            return ReferralSnapshot(
                code: code,
                title: title,
                approved: approved,
                region: region,
                windowDays: windowDays,
                tags: tags,
                unit: unit,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a referral snapshot in status created.
    static func newReferralSnapshot(_ code: String, title: String) -> ReferralSnapshot {
        return ReferralSnapshot(
            code: code,
            title: title,
            approved: false,
            region: "",
            windowDays: 0,
            tags: [],
            unit: "",
            sequence: 0,
            status: ReferralSnapshotStatus.created
        )
    }
}
