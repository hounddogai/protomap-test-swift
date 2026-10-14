import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board variance is in its life cycle.
    enum BedBoardVarianceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a bed board variance and its current status.
    final class BedBoardVariance {
        var code: String
        var title: String
        var minimum: Double
        var limit: Int
        var approved: Bool
        var segment: String
        var attributes: [String: String]
        var status: BedBoardVarianceStatus

        init(code: String, title: String, minimum: Double, limit: Int, approved: Bool, segment: String, attributes: [String: String], status: BedBoardVarianceStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.limit = limit
            self.approved = approved
            self.segment = segment
            self.attributes = attributes
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

        func canMoveTo(_ next: BedBoardVarianceStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == BedBoardVarianceStatus.ready || next == BedBoardVarianceStatus.stopped
            case .ready:
                return next == BedBoardVarianceStatus.draining || next == BedBoardVarianceStatus.stopped
            case .draining:
                return next == BedBoardVarianceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((minimum + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardVariance {
            return BedBoardVariance(
                code: code,
                title: title,
                minimum: minimum,
                limit: limit,
                approved: approved,
                segment: segment,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a bed board variance in status idle.
    static func newBedBoardVariance(_ code: String, title: String) -> BedBoardVariance {
        return BedBoardVariance(
            code: code,
            title: title,
            minimum: 0.0,
            limit: 0,
            approved: false,
            segment: "",
            attributes: [:],
            status: BedBoardVarianceStatus.idle
        )
    }
}
