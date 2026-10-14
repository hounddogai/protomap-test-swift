import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped census baseline is in its life cycle.
    enum CappedCensusBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped census baseline as the census team keeps it.
    final class CappedCensusBaseline {
        var code: String
        var title: String
        var region: String
        var ratio: Double
        var unit: String
        var copay: Double
        var refills: Int
        var tags: [String]
        var attempts: Int
        var quantity: Int
        var summary: String
        var status: CappedCensusBaselineStatus

        init(code: String, title: String, region: String, ratio: Double, unit: String, copay: Double, refills: Int, tags: [String], attempts: Int, quantity: Int, summary: String, status: CappedCensusBaselineStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.ratio = ratio
            self.unit = unit
            self.copay = copay
            self.refills = refills
            self.tags = tags
            self.attempts = attempts
            self.quantity = quantity
            self.summary = summary
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

        func canMoveTo(_ next: CappedCensusBaselineStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
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
                return next == CappedCensusBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCensusBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped census baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func projectedVolume() -> Double {
            return ((Double(attempts) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> CappedCensusBaseline {
            return CappedCensusBaseline(
                code: code,
                title: title,
                region: region,
                ratio: ratio,
                unit: unit,
                copay: copay,
                refills: refills,
                tags: tags,
                attempts: attempts,
                quantity: quantity,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped census baseline in status created.
    static func newCappedCensusBaseline(_ code: String, title: String) -> CappedCensusBaseline {
        return CappedCensusBaseline(
            code: code,
            title: title,
            region: "",
            ratio: 0.0,
            unit: "",
            copay: 0.0,
            refills: 0,
            tags: [],
            attempts: 0,
            quantity: 0,
            summary: "",
            status: CappedCensusBaselineStatus.created
        )
    }
}
