import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial group is in its life cycle.
    enum DenialGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A denial group as the denial team keeps it.
    final class DenialGroup {
        var code: String
        var title: String
        var externalRef: String
        var timezone: String
        var active: Bool
        var refills: Int
        var durationMinutes: Int
        var cost: Double
        var tags: [String]
        var status: DenialGroupStatus

        init(code: String, title: String, externalRef: String, timezone: String, active: Bool, refills: Int, durationMinutes: Int, cost: Double, tags: [String], status: DenialGroupStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.timezone = timezone
            self.active = active
            self.refills = refills
            self.durationMinutes = durationMinutes
            self.cost = cost
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DenialGroupStatus) -> Bool {
            switch status {
            case .new:
                return next == DenialGroupStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: DenialGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func weightedExposure() -> Double {
            return ((Double(durationMinutes) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> DenialGroup {
            return DenialGroup(
                code: code,
                title: title,
                externalRef: externalRef,
                timezone: timezone,
                active: active,
                refills: refills,
                durationMinutes: durationMinutes,
                cost: cost,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a denial group in status new.
    static func newDenialGroup(_ code: String, title: String) -> DenialGroup {
        return DenialGroup(
            code: code,
            title: title,
            externalRef: "",
            timezone: "",
            active: false,
            refills: 0,
            durationMinutes: 0,
            cost: 0.0,
            tags: [],
            status: DenialGroupStatus.new
        )
    }
}
