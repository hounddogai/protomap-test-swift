import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered read group is in its life cycle.
    enum TieredReadGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered read group and its current status.
    final class TieredReadGroup {
        var code: String
        var name: String
        var batchSize: Int
        var cost: Double
        var attributes: [String: String]
        var region: String
        var allergy: String
        var startsAt: Int
        var status: TieredReadGroupStatus

        init(code: String, name: String, batchSize: Int, cost: Double, attributes: [String: String], region: String, allergy: String, startsAt: Int, status: TieredReadGroupStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.cost = cost
            self.attributes = attributes
            self.region = region
            self.allergy = allergy
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredReadGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredReadGroupStatus.active
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredReadGroupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredReadGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered read group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered read group") \(code)"
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

        func netVolume() -> Double {
            return (Double(startsAt) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> TieredReadGroup {
            return TieredReadGroup(
                code: code,
                name: name,
                batchSize: batchSize,
                cost: cost,
                attributes: attributes,
                region: region,
                allergy: allergy,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a tiered read group in status draft.
    static func newTieredReadGroup(_ code: String, name: String) -> TieredReadGroup {
        return TieredReadGroup(
            code: code,
            name: name,
            batchSize: 0,
            cost: 0.0,
            attributes: [:],
            region: "",
            allergy: "",
            startsAt: 0,
            status: TieredReadGroupStatus.draft
        )
    }
}
