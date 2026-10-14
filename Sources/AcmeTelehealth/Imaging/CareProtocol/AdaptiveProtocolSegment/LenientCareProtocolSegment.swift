import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient care protocol segment is in its life cycle.
    enum LenientCareProtocolSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One lenient care protocol segment, with what the planners need to act on it.
    final class LenientCareProtocolSegment {
        var code: String
        var title: String
        var margin: Double
        var revision: Int
        var approved: Bool
        var graceDays: Int
        var floorValue: Double
        var refills: Int
        var locale: String
        var rate: Double
        var category: String
        var status: LenientCareProtocolSegmentStatus

        init(code: String, title: String, margin: Double, revision: Int, approved: Bool, graceDays: Int, floorValue: Double, refills: Int, locale: String, rate: Double, category: String, status: LenientCareProtocolSegmentStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.revision = revision
            self.approved = approved
            self.graceDays = graceDays
            self.floorValue = floorValue
            self.refills = refills
            self.locale = locale
            self.rate = rate
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

        func canMoveTo(_ next: LenientCareProtocolSegmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientCareProtocolSegmentStatus.draining || next == LenientCareProtocolSegmentStatus.stopped
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: LenientCareProtocolSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient care protocol segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveVolume() -> Double {
            return (rate * margin * 100).rounded() / 100
        }

        func copyValue() -> LenientCareProtocolSegment {
            return LenientCareProtocolSegment(
                code: code,
                title: title,
                margin: margin,
                revision: revision,
                approved: approved,
                graceDays: graceDays,
                floorValue: floorValue,
                refills: refills,
                locale: locale,
                rate: rate,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient care protocol segment in status idle.
    static func newLenientCareProtocolSegment(_ code: String, title: String) -> LenientCareProtocolSegment {
        return LenientCareProtocolSegment(
            code: code,
            title: title,
            margin: 0.0,
            revision: 0,
            approved: false,
            graceDays: 0,
            floorValue: 0.0,
            refills: 0,
            locale: "",
            rate: 0.0,
            category: "",
            status: LenientCareProtocolSegmentStatus.idle
        )
    }
}
