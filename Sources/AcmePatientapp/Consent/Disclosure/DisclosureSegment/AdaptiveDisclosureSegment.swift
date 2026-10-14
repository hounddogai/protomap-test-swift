import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive disclosure segment is in its life cycle.
    enum AdaptiveDisclosureSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A adaptive disclosure segment as the disclosure team keeps it.
    final class AdaptiveDisclosureSegment {
        var code: String
        var name: String
        var facility: String
        var endsAt: Int
        var startsAt: Int
        var region: String
        var budget: Double
        var archived: Bool
        var category: String
        var status: AdaptiveDisclosureSegmentStatus

        init(code: String, name: String, facility: String, endsAt: Int, startsAt: Int, region: String, budget: Double, archived: Bool, category: String, status: AdaptiveDisclosureSegmentStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.region = region
            self.budget = budget
            self.archived = archived
            self.category = category
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

        func canMoveTo(_ next: AdaptiveDisclosureSegmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == AdaptiveDisclosureSegmentStatus.warming
            case .warming:
                return next == AdaptiveDisclosureSegmentStatus.draining || next == AdaptiveDisclosureSegmentStatus.stopped
            case .ready:
                return next == AdaptiveDisclosureSegmentStatus.draining || next == AdaptiveDisclosureSegmentStatus.stopped
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

        func moveTo(_ next: AdaptiveDisclosureSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive disclosure segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return ((Double(startsAt) + budget) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDisclosureSegment {
            return AdaptiveDisclosureSegment(
                code: code,
                name: name,
                facility: facility,
                endsAt: endsAt,
                startsAt: startsAt,
                region: region,
                budget: budget,
                archived: archived,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive disclosure segment in status idle.
    static func newAdaptiveDisclosureSegment(_ code: String, name: String) -> AdaptiveDisclosureSegment {
        return AdaptiveDisclosureSegment(
            code: code,
            name: name,
            facility: "",
            endsAt: 0,
            startsAt: 0,
            region: "",
            budget: 0.0,
            archived: false,
            category: "",
            status: AdaptiveDisclosureSegmentStatus.idle
        )
    }
}
