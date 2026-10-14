import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census adjustment is in its life cycle.
    enum CensusAdjustmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A census adjustment. Its code is unique within a tenant.
    final class CensusAdjustment {
        var code: String
        var title: String
        var windowDays: Int
        var minimum: Double
        var ward: String
        var source: String
        var score: Double
        var ceiling: Double
        var tags: [String]
        var status: CensusAdjustmentStatus

        init(code: String, title: String, windowDays: Int, minimum: Double, ward: String, source: String, score: Double, ceiling: Double, tags: [String], status: CensusAdjustmentStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.minimum = minimum
            self.ward = ward
            self.source = source
            self.score = score
            self.ceiling = ceiling
            self.tags = tags
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

        func canMoveTo(_ next: CensusAdjustmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CensusAdjustmentStatus.ready
            case .ready:
                return next == CensusAdjustmentStatus.draining || next == CensusAdjustmentStatus.stopped
            case .draining:
                return next == CensusAdjustmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("census adjustment") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return (ceiling * minimum * 100).rounded() / 100
        }

        func copyValue() -> CensusAdjustment {
            return CensusAdjustment(
                code: code,
                title: title,
                windowDays: windowDays,
                minimum: minimum,
                ward: ward,
                source: source,
                score: score,
                ceiling: ceiling,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a census adjustment in status idle.
    static func newCensusAdjustment(_ code: String, title: String) -> CensusAdjustment {
        return CensusAdjustment(
            code: code,
            title: title,
            windowDays: 0,
            minimum: 0.0,
            ward: "",
            source: "",
            score: 0.0,
            ceiling: 0.0,
            tags: [],
            status: CensusAdjustmentStatus.idle
        )
    }
}
