import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense baseline is in its life cycle.
    enum DispenseBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A dispense baseline as the dispense team keeps it.
    final class DispenseBaseline {
        var code: String
        var title: String
        var region: String
        var graceDays: Int
        var channel: String
        var tags: [String]
        var ratio: Double
        var endsAt: Int
        var reviewer: String
        var acuity: Int
        var status: DispenseBaselineStatus

        init(code: String, title: String, region: String, graceDays: Int, channel: String, tags: [String], ratio: Double, endsAt: Int, reviewer: String, acuity: Int, status: DispenseBaselineStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.graceDays = graceDays
            self.channel = channel
            self.tags = tags
            self.ratio = ratio
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DispenseBaselineStatus.inReview || next == DispenseBaselineStatus.reopened
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DispenseBaselineStatus.reopened || next == DispenseBaselineStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: DispenseBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return ((ratio + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseBaseline {
            return DispenseBaseline(
                code: code,
                title: title,
                region: region,
                graceDays: graceDays,
                channel: channel,
                tags: tags,
                ratio: ratio,
                endsAt: endsAt,
                reviewer: reviewer,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a dispense baseline in status open.
    static func newDispenseBaseline(_ code: String, title: String) -> DispenseBaseline {
        return DispenseBaseline(
            code: code,
            title: title,
            region: "",
            graceDays: 0,
            channel: "",
            tags: [],
            ratio: 0.0,
            endsAt: 0,
            reviewer: "",
            acuity: 0,
            status: DispenseBaselineStatus.`open`
        )
    }
}
