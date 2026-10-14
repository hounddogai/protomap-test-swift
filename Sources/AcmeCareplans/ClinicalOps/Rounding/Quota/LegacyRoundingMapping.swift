import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy rounding mapping is in its life cycle.
    enum LegacyRoundingMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A legacy rounding mapping. Its code is unique within a tenant.
    final class LegacyRoundingMapping {
        var code: String
        var title: String
        var encounterID: String
        var cost: Double
        var category: String
        var country: String
        var ratio: Double
        var endsAt: Int
        var pinned: Bool
        var status: LegacyRoundingMappingStatus

        init(code: String, title: String, encounterID: String, cost: Double, category: String, country: String, ratio: Double, endsAt: Int, pinned: Bool, status: LegacyRoundingMappingStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.cost = cost
            self.category = category
            self.country = country
            self.ratio = ratio
            self.endsAt = endsAt
            self.pinned = pinned
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

        func canMoveTo(_ next: LegacyRoundingMappingStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LegacyRoundingMappingStatus.draining || next == LegacyRoundingMappingStatus.stopped
            case .ready:
                switch next {
                case .draining:
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

        func moveTo(_ next: LegacyRoundingMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy rounding mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy rounding mapping") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((cost + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyRoundingMapping {
            return LegacyRoundingMapping(
                code: code,
                title: title,
                encounterID: encounterID,
                cost: cost,
                category: category,
                country: country,
                ratio: ratio,
                endsAt: endsAt,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy rounding mapping in status idle.
    static func newLegacyRoundingMapping(_ code: String, title: String) -> LegacyRoundingMapping {
        return LegacyRoundingMapping(
            code: code,
            title: title,
            encounterID: "",
            cost: 0.0,
            category: "",
            country: "",
            ratio: 0.0,
            endsAt: 0,
            pinned: false,
            status: LegacyRoundingMappingStatus.idle
        )
    }
}
